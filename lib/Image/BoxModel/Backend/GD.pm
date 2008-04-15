package Image::BoxModel::Backend::GD;

use strict;
use warnings;

use Image::BoxModel::Lowlevel;
our @ISA = ("Image::BoxModel::Lowlevel");

sub DrawRectangle{
	my $image = shift;
	my %p = @_;
	
	if (exists $p{color}){	#this is the first invocation: a simple rectangle with no border..
		print $image->{GD} -> filledRectangle($p{left},$p{top},$p{right},$p{bottom},$image->{colors}{$p{color}});
	}
	elsif (exists $p{fill_color} and exists $p{border_color}){	#and here the 2nd: rectangle with border..
		print $image->{GD} -> filledRectangle($p{left},$p{top},$p{right},$p{bottom},$image->{colors}{$p{fill_color}});
		print $image->{GD} -> rectangle($p{left},$p{top},$p{right},$p{bottom},$image->{colors}{$p{border_color}});
	}
	else{
		die __PACKAGE__,": Either specify 'color' or 'fill_color' && 'border_color'. Die.";
	}
	
	$image -> print_message ("DrawRectangle with ",__PACKAGE__,"::DrawRectangle\n");
}

sub TextSize{
	my $image = shift;
	my %p = @_;
	
	my (undef, undef, undef, @corner) = gd_text_size($p{font}, $p{textsize}, $p{text});
	
	return @corner;
}

sub DrawText{
	my $image = shift;
	my %p = @_;
	
	$image -> print_message ("DrawText with ",__PACKAGE__,"::DrawText\n");
	my ($capital, $descender, $line_spacing, @corner) = gd_text_size($p{font}, $p{textsize}, $p{text});

	my ($width, $height) = $image->GetTextSize (%p);
	
	my $warning =  "box '$p{box}' is to small for text: \"$p{text}\". Drawing anyway.\n (height: text: $height\tbox: ".$image -> {$p{box}}{height}."\n width: text: $width\tbox:".$image -> {$p{box}}{width}."\n"
		if (($width > $image -> {$p{box}}{width}) || ($height > $image -> {$p{box}}{height}));

	#first, we need to determine the center of the text-box (which is the center of rotation):
	#"Center is default:
	my $x_rotation_center = $p{x_box_center};
	my $y_rotation_center = $p{y_box_center};

	if ($p{position} =~ /North/i){
		$y_rotation_center = $image->{$p{box}}{top} + $height / 2;
	}
	elsif ($p{position} =~ /South/i){
		$y_rotation_center = $image->{$p{box}}{bottom} - $height / 2;
	}
	if ($p{position} =~ /West/i){	#This if is on purpose.. It may be ok. to have a combination like NortWest, but not NorthSouth ;-)
		$x_rotation_center = $image->{$p{box}}{left} + $width / 2;
	}
	elsif ($p{position} =~ /East/i){
		$x_rotation_center = $image->{$p{box}}{right} - $width / 2;
	}

	#draw a small rectangle if desired
	if ($p{background}){
		$image->{GD} -> filledRectangle($x_rotation_center-$width/2,$y_rotation_center-$height/2,$x_rotation_center+$width/2,$y_rotation_center+$height/2,$image->{colors}{$p{background}});
		$image->{GD} -> rectangle($x_rotation_center-$width/2,$y_rotation_center-$height/2,$x_rotation_center+$width/2,$y_rotation_center+$height/2,$image->{colors}{black});
	}

	#show rotation centre; debug only
	#~ #$image->{GD} -> rectangle ($x_rotation_center -1, $y_rotation_center -1, $x_rotation_center +1, $y_rotation_center +1, $image->{colors}{black});

	#second, we need to draw each line, aligned as requested.

	my @lines = split (/\n/, $p{text});
	my $e = 1;
	my ($unrotated_width, $unrotated_height) = $image->GetTextSize (%p, rotate => 0);

	foreach my $line (@lines){
		
		my $y = $y_rotation_center - $unrotated_height / 2 + $capital * $e + $line_spacing * ($e-1); #Height of capital Ä * lines + $spacing * (lines-1)
		
		my @line_bounds = GD::Image ->stringFT(0,$p{font},$p{textsize},0,0,0,$line, {resolution=>"72,72"});
		my $x;
		if ($p{align} =~ /^center$/i){
			$x = $x_rotation_center -  (($line_bounds[2] - $line_bounds[0]) / 2);	
		}
		elsif ($p{align} =~ /^right$/i){
			$x = $x_rotation_center + $unrotated_width / 2 - ($line_bounds[2] - $line_bounds[0]) ;
		}
		else{
			$x = $x_rotation_center - $unrotated_width / 2;
		}
		
		#show text (unrotated), debug only:
		#~ #$image->{GD}->stringFT($image->{colors}{black},$p{font},$p{textsize},0,$x,$y,$line);
		
		($x, $y) = $image->rotation($x, $y, $x_rotation_center, $y_rotation_center, $p{rotate}) unless ($p{rotate} == 0);
		$image->{GD}->stringFT($image->{colors}{$p{fill}},$p{font},$p{textsize},-$p{rotate}/180*$image->{PI},$x,$y,$line,{resolution=>"72,72"});	
		
		#show point where GD starts to draw text, debug only
		#~ #$image->{GD} -> rectangle ($x -1, $y -1, $x+1, $y +1, $image->{colors}{black});	
		
		$e ++;
	}
	
	return $warning;
}

sub Save{
	my $image = shift;
	my %p = @_;
	$image -> print_message ("Save with ", __PACKAGE__, "\n");
	open (PNG, ">$p{file}") or die "can't open $p{file}: $!";
	print PNG $image->{GD}->png;
	close PNG;
}

#this sub does some calculations for some routines. As soon as all GD-work is done here, I will see if this sub is still the best way to do it..
sub gd_text_size{
	my ($font, $size, $text) = @_;
	
	my @corner;
	
	my @bounds = GD::Image->stringFT(0,$font,$size,0,0,0,"Ä", {resolution=>"72,72"});
	my $capital = $bounds[1]- $bounds[7];

	@bounds = GD::Image->stringFT(0,$font,$size,0,0,0,"Äg", {resolution=>"72,72"});
	my $descender = $bounds[1]- $bounds[7] - $capital;
			
	my $line_spacing = $descender / 2;	#unimplemented: $line_spacing as argument

	($corner[3]{x}, undef, $corner[2]{x}, undef, $corner[1]{x}, undef, $corner[0]{x}, undef) = GD::Image->stringFT(0,$font,$size,0,0,0,$text, {resolution=>"72,72"});	
		#Get bounds of *unrotated* text
		# @bounds[0,1]  Lower left corner (x,y)
		# @bounds[2,3]  Lower right corner (x,y)
		# @bounds[4,5]  Upper right corner (x,y)
		# @bounds[6,7]  Upper left corner (x,y)

	my @lines = split (/\n/, $text);

	#define y-values according to test-string. This is not perfectly equal to the findings of the freetype-engine, but gives satisfiable, reliable results.
	$corner[0]{y} =0 - $capital;
	$corner[1]{y} = $corner[0]{y};

	$corner[2]{y} = $corner[1]{y} + $capital * scalar(@lines) + $line_spacing * (scalar(@lines)-1) + $descender;	#baseline (=height of capital Ä) * number_of_lines + line_spacing * (number_of_lines-1) + descender
	$corner[3]{y} = $corner[2]{y};
	
	return $capital, $descender, $line_spacing, @corner;
}

1;