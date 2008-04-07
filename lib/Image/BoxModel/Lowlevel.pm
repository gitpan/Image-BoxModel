package Image::BoxModel::Lowlevel;

use warnings;
use strict;

use POSIX;	#for ceil() in ::Box

=head1 NAME

Image::BoxModel - Module for defining boxes on an image an putting things on them

=head1 SYNOPSIS

  For an example and general information see Image::BoxModel.pm

=head1 DESCRIPTION

Image::BoxModel::Lowlevel implements some basic functionality. 

It does so by using the methods from Image::BoxModel::Backend::[LIBRARY]
The thing is, this is in the stage of being implemented at the moment.

There are more backends planned and more functionality for each backend.
(backends, patches, wishes are very welcome - in this order ;-)

Image::BoxModel::Lowlevel can be used directly, which is considered painful. You need to specify the size of a box before you can put text on it, for example. This can lead to non-fitting text.

Better use the Modules

Image::BoxModel::Text for all things text

and

Image::BoxModel::Chart for charts.

The bad thing is, these modules are yet to be written. ;-)

=head2 Methods:

=cut

#########################
#Get width & height of a Box
#########################

=head3 GetBoxSize

 ($width, $height) = $image -> GetBoxSize (box => "name_of_your_box");

=cut

sub GetBoxSize{
	my $image = shift;
	my %p = @_;
	
	if ((exists $p{box} && defined $p{box}) && (exists $image->{$p{box}}{width})){
		return $image->{$p{box}}{width}, $image->{$p{box}}{height};
	}
	else{
		return "Box '$p{box}' is not (correctly, at least) defined";
	}
}



#########################
# Add a new box and resize another one (the "free"-box unless resize => box-to-resize is set)
#########################

=head3 Box

If you don't specify 'resize => $name_of_box_to_be_resized', the standard-box 'free' is chosen.

 $image -> Box (
	position =>[left|right|top|bottom], 
	width=> $x, 
	height => $y, 
	name => $name_of_new_box
 );

=cut

sub Box{
	
	my $image = shift;
	my %p = @_;	#%p holds the _p_arameters
	my $resize = $p{resize} || "free";
	
	die __PACKAGE__,"::Box: Mandatory parameter name missing. No box added" unless $p{name};
	return "$p{name} already exists. No box added" if (exists $image->{$p{name}});
	
	#return if width or height is not specified. 
	#(height wenn adding at top or bottom, width wen adding at left or right side.)
	if ($p{position} eq "top" or $p{position} eq "bottom"){
		return "Box: Please specify height > 0. No box added\n" unless (exists $p{height} and $p{height} > 0);
	}
	elsif ($p{position} eq "left" or $p{position} eq "right"){
		return "Box: Please specify width > 0. No box added\n" unless (exists $p{width} and $p{width} > 0);
	}
	
	$image -> print_message ("Add Box \"$p{name}\" with ", __PACKAGE__,"\n");
	
	
	$image->{$p{name}}={	#First we make the new box as big as the field which will be resized..
		top		=> $image->{$resize}{top},
		bottom	=> $image->{$resize}{bottom},
		left		=> $image->{$resize}{left} ,
		right		=> $image->{$resize}{right},
	};	
	
	#.. then we overwrite as needed.
	
	$p{width} = ceil ($p{width}) if exists $p{width};
	$p{height} = ceil ($p{height}) if exists $p{height};
	
	if ($p{position} eq "top"){
		$image->{$p{name}}{bottom} = $image->{$resize}{top} + $p{height};	
		
		#The top margin of the resized field is set to the bottom of the new box.
		$image->{$resize}{top} = $image->{$p{name}}{bottom}+1;			
	}																			
	elsif ($p{position} eq "bottom"){
		$image->{$p{name}}{top} = $image->{$resize}{bottom} - $p{height};
		$image->{$resize}{bottom} = $image->{$p{name}}{top}-1;
	}
	elsif ($p{position} eq "left"){
		$image->{$p{name}}{right} = $image->{$resize}{left} + $p{width};
		$image->{$resize}{left} = $image->{$p{name}}{right}+1;
	}
	elsif ($p{position} eq "right"){
		$image->{$p{name}}{left} = $image->{$resize}{right} - $p{width};
		$image->{$resize}{right} = $image->{$p{name}}{left}-1;
	}
	else {
		return "Image::BoxModel::Lowlevel::Box: Position $p{position} unknown. No box added";
		
	}
	
	if ((exists $p{background}) && (defined $p{background})){
		$image-> DrawRectangle(
			left => $image->{$p{name}}{left}, 
			right => $image->{$p{name}}{right}, 
			top => $image->{$p{name}}{top}, 
			bottom => $image->{$p{name}}{bottom}, 
			color => $p{background}
		);
	}
	
	$image->{$p{name}}{width} = $image->{$p{name}}{right} - $image->{$p{name}}{left};
	$image->{$p{name}}{height} = $image->{$p{name}}{bottom} - $image->{$p{name}}{top};
	
	$image->{$resize}{height} = $image->{$resize}{bottom} - $image->{$resize}{top};	#calculate these values for later use.. laziness
	$image->{$resize}{width} = $image->{$resize}{right} - $image->{$resize}{left};
	
	return;
}

#########################
# Add Floating Box. These boxes can reside anywhere and can overlap. Poor error-checking!
#########################

=head3 FloatBox

To position a free-floating box wherever you want. There is virtually no error-checking, so perhaps better keep your hands off. ;-)

 $image -> FloatBox(
	top =>$top, 
	bottom=>$bottom, 
	right=> $right, 
	left=> $top, 
	name=>"whatever_you_call_it", 
	background =>[color]
 );

=cut

sub FloatBox{
	my $image = shift;
	my %p =@_;
	return "$p{name} already exists. No FloatBox added" if (exists $image->{$p{name}});
	foreach ("top", "bottom", "left", "right"){
		return __PACKAGE__,"::FloatBox: argument $_ missing. No FloatBox added" unless (exists $p{$_});
		$image->{$p{name}}{$_} = $p{$_};
	}
	
	$image -> print_message ("Add FloatBox \"$p{name}\" with ", __PACKAGE__,"\n");
	
	my $top = $image->{$p{name}}{top};
	my $bottom = $image->{$p{name}}{bottom};
	my $left = $image->{$p{name}}{left};
	my $right = $image->{$p{name}}{right};
	if ((exists $p{background}) && (defined $p{background})){
		$image-> DrawRectangle(left => $left, right => $right, top => $top, bottom => $bottom, color => $p{background});
	}
	
	$image->{$p{name}}{width} = $image->{$p{name}}{right} - $image->{$p{name}}{left};
	$image->{$p{name}}{height} = $image->{$p{name}}{bottom} - $image->{$p{name}}{top};
	
	return
}

#########################
# Get width & height of (rotated) text.
#########################

=head3 GetTextSize

Get the boundig size of (rotated) text. Very useful to find out how big boxes need to be.
 ($width, $height) = GetTextSize(
	text => "Your Text",
	textsize => [number],
	rotate => [in degrees, may be negative as well]
 );

=cut

sub GetTextSize{
	my $image = shift;
	my %p = (
		rotate => 0,
		font => "verdana.ttf",
		@_
	);
	
	#die if the mandatory parameters are missing
	my $warning;
	foreach ("text", "textsize"){
		$warning .= "Mandatory parameter \"$_\" missing. " unless (exists $p{$_});
	}
	die __PACKAGE__,"::GetTextSize: ".$warning . "dying." if ($warning);
	
	#get x&y of all corners:
	#@corner[0-3]{x|y}
	my @corner = $image->TextSize(text => $p{text}, font => $p{font}, textsize => $p{textsize});
	
	#rotate all 4 corners
	unless ($p{rotate} == 0){	
		for (my $i = 0; $i < scalar(@corner); $i++){
			($corner[$i]{x}, $corner[$i]{y}) =  $image -> rotation ($corner[$i]{x}, $corner[$i]{y}, 0, 0, $p{rotate});
		}
	}
	
	my %most =(
		left => 0,
		right => 0,
		top => 0,
		bottom =>0
	);
	
	#find the left-, right-, top- and bottommost values.
	foreach (@corner){
		$most{left} = $_->{x} if ($_->{x} < $most{left});
		$most{right} = $_->{x} if ($_->{x} > $most{right});
		$most{top} = $_->{y} if ($_->{y} < $most{top});
		$most{bottom} = $_->{y} if ($_->{y} > $most{bottom});
	}
	return $most{right}- $most{left}, $most{bottom}-$most{top};	#return width and height
}

#########################
# Add text to a box
#########################

=head3 Text

Put (rotated, antialized) text on a box. Takes a bunch of parameters, of which "text" and "textsize" are mandatory. 

 $image -> Text(
	text => 	$text,
	textsize => [number],
	fill=>		"black",				#color of text, will be renamed soon
	font =>	"verdana",
	rotate=>	[in degrees, may be negative as well],
	box => 	"free",
	align => 	[Left|Center|Right]",		#align is how multiline-text is aligned
	position =>[Center				#position is how text will be positioned inside its box
			NorthWest|
			North|
			NorthEast|
			West|
			SoutEast|
			South|
			SouthWest|
			West],
	background=> [color]				#rather for debugging
 );

=cut

sub Text{
	my $image = shift;
	my %p = (
		fill=>"black",
		font => "verdana",
		rotate=>0,
		box => "free",
		rotate => 0,
		align => "Center",
		position => "Center",
		@_
	);
	my $warning;
	foreach ("text", "textsize"){
		$warning .= "Mandatory parameter \"$_\" missing. " unless (exists $p{$_});
	}
	
	#if the box does not exist (Box couldn't / didn't want to make it due to missing parameters), we can't add text.
	#(It's better if we don't want to..)
	$warning .= "Box '$p{box}' does not exist. " unless (exists $image->{$p{box}});
	
	return "Text: ".$warning . "No Text added.\n" if ($warning);
	
	#center of box = left + (right-left) /2
	#later we will rotate the text around the center of the box.
	$p{x_box_center} = $image->{$p{box}}{left} + ($image->{$p{box}}{right} - $image->{$p{box}}{left}) / 2;	
	$p{y_box_center} = $image->{$p{box}}{top} + ($image->{$p{box}}{bottom} - $image->{$p{box}}{top}) / 2; 
	
	#DrawText lives in ::Backend::[your_library], because it has to do much library-specific calculations
	my $w = $image -> DrawText(%p);
	$warning .= $w if $w;
	
	$image -> print_message ("Add Text to Box \"$p{box}\" with ",__PACKAGE__,"\n");
	return $warning || return;	#to avoid "uninitialized value in calling line when using -w"
}

=head3 Save

Save the image to file. There is no error-checking at the moment if your chosen library supports the desired file-type.

=cut

#There is no Save here really, because it's in ::Backend::[library]

=head3 Internal methods:

(documentation for myself rather than the user)

=head4 rotation

To rotate a given point by any point. It takes the angle in degrees, which is very comfortable to me. 
If you want to rotate something, feel free to use it. :-)

 ($x, $y) = $image -> rotation($x, $y, $x_center, $y_center, $angle);

=cut

sub rotation{
	my $image = shift;
	my ($x, $y, $x_center, $y_center, $angle) = @_;
	#~ print "X: $x Y: $y x-center: $x_center y-center: $y_center angle: $angle\n";
	
	$angle = $image->{PI} / (360 / $angle) * 2;
	
	my $sin = sin ($angle);
	my $cos = cos ($angle);
	
	my $x1=$x;
	my $y1=$y;
	
	$x = ($x1 * $cos) - ($y1 * $sin) - ($x_center * $cos) + ($y_center * $sin) + $x_center;
	$y = ($x1 * $sin) + ($y1 * $cos) - ($x_center * $sin) - ($y_center * $cos) + $y_center;
	
	return $x, $y;
}

=head4 print_message

Checks if verbose is on and then prints messages.
 $image -> print_message("Text");

=cut

sub print_message{
	my $image = shift;
	print @_ if $image->{verbose};
}


1;
__END__

=head2 EXPORT

Nothing. Please use the object oriented interface.



=head1 SEE ALSO

Nowhere at the moment.

=head1 AUTHOR

Matthias Bloch, <lt>matthias at puffin ch<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by :m)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
