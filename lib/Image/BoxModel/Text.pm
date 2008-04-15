package Image::BoxModel::Text;

use warnings;
use strict;

=head1 NAME

Image::BoxModel::Text - Text functions for Image::BoxModel

=head1 SYNOPSIS

  For an example and general information see Image::BoxModel.pm

=head1 DESCRIPTION

Image::BoxModel::Text implements direct inserting of text. It has the following method which a Image::BoxModel object inherit.

It uses Image::BoxModel::Lowlevel for defining boxes and drawing text. See there for more information.

=head2 Method

=head3 Annotate

 $image -> Annotate (
	text => $text 					#mandatory
	position => [top|bottom|right|left],
	textsize => $size,
	font => $font,
	rotate => [in degrees, may be negative as well],
	align => [Center|Left|Right],			#align is how multiline-text is aligned
	text_position => [Center			#position is how text will be positioned inside its box
			NorthWest|
			North|
			NorthEast|
			West|
			SoutEast|
			South|
			SouthWest|
			West],
	background => (color),
	padding_right => [number],
	padding_left => [number],
	padding_top => [number],
	padding_bottom=> [number],
 )

All parameters except "text" are preset with defaults. These are the first value above or generally "0" for numbers (except "20" for textsize), and "white" for colors.

=cut

sub Annotate{
	my $background = shift;
	my %p = (
		position=>"top",
		textsize => 20,
		font => "verdana",
		rotate => 0,
		align => "Center",
		background => "white",
		padding_right => 0,
		padding_left => 0,
		padding_top => 0,
		padding_bottom => 0,
		
		@_
	);
	
	my $box_position = "top";
	my $text_position = "Center";
	
	$box_position = $p{box_position} if (exists $p{box_position});
	$text_position = $p{text_position} if (exists $p{text_position});
	
	#autogenerated boxes are numbered, starting with 1
	my $e = 1;
	$e++ while (exists $background -> {$e});
	
	my ($width, $height) = $background -> GetTextSize(
		text => $p{text}, 
		textsize => $p{textsize}, 
		rotate => $p{rotate}
	);
	
	$background -> Box(
		position =>$box_position, 
		width=> $width+$p{padding_right}+$p{padding_left}, 
		height => $height+$p{padding_top}+$p{padding_bottom}, 
		name=> $e, 
		background => $p{background}
	);
	
	#if there is some padding, little empty boxes are added:
	foreach ("padding_top", "padding_bottom", "padding_left", "padding_right"){
		(my $position = $_) =~ s/.+_//;
		
		$background-> Box(
			resize=> $e, 
			position =>$position, 
			width=> $p{$_}-1, 
			height => $p{$_}-1, 
			name => $e.$_, 
			background => $p{background} 
		) if ($p{$_} > 0);
	}
	
	$background -> Text(
		box => $e, 
		text=> $p{text}, 
		font => $p{font}, 
		textsize => $p{textsize}, 
		align=>$p{align}, 
		position=> $text_position, 
		rotate => $p{rotate}
	);
}

1