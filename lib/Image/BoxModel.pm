package Image::BoxModel;	

#~ use 5.008008;
use warnings;
use strict;
our $VERSION = '0.07';

use Image::BoxModel::Lowlevel;	#Lowlevel methods like boxes, text, graphic primitives
use Image::BoxModel::Text;		#Automatically makes a fitting box and puts text on it. Uses Lowlevel methods

our @ISA = ("Image::BoxModel::Text", "Image::BoxModel::Lowlevel"); 



sub new{
	my $class = shift;
	
	#Define a new image an preset some values before..
	my $image ={
		width => 400, 
		height => 300,
		background => "white",
		lib=> "GD",	#IM or GD ;-)
		PI => 3.14159265358979,
		verbose => "0",	#if we print many messages about what the programs do.
		#.. adding the users parameters
		@_
	};
	$image->{height}--;	#Because a picture of 400 pixels height ranges from 0-399
	$image->{width}--;
		
	$image->{free} = {	#This is the standard-box. It will shrink when a new box is added. Now it fills the whole background.
		top => 0,
		bottom => $image->{height},
		height => $image -> {height},
		left => 0,
		right => $image->{width},
		width => $image->{width}
	};
	
	#Now follow the definitions of the backend-libraries
	#Inheritance is granted by using the appropriate backend-modules.
	#This means that if GD is used, then the image-object has ::Backend::GD as its parent, so therefore the appropriate methods in ::Backen::GD are found.
	#I don't know if this is good software design..
	
	#the "new-constructors need to be moved into ::Backend. Someday.
	
	if ($image -> {lib} eq "IM"){
		require Image::Magick;
		require Image::BoxModel::Backend::IM;
		push @ISA, "Image::BoxModel::Backend::IM";
		
		$image->{IM} = new Image::Magick; 
		$image->{IM} -> Set(size => $image->{width}."x".$image->{height}); 
		$image->{IM} -> Read("xc:$image->{background}"); 
	}
	elsif ($image -> {lib} eq "GD"){
		require GD;
		require Image::BoxModel::Backend::GD;
		push @ISA, "Image::BoxModel::Backend::GD";
		
		$image->{GD} = new GD::Image($image->{width}+1,$image->{height}+1);
		my $a = $image->{GD}->useFontConfig(1);
		print "Fontconfig not available!" if ($a == 0);
		
		#this should be in ::Backend::GD
		$image->{colors}{white} = $image->{GD}->colorAllocate(255,255,255);
		$image->{colors}{black} = $image->{GD}->colorAllocate(0,0,0);       
		$image->{colors}{red} = $image->{GD}->colorAllocate(255,0,0);     
		$image->{colors}{darkred} = $image->{GD}->colorAllocate(126,0,0);   		
		$image->{colors}{blue} = $image->{GD}->colorAllocate(0,0,255);
		$image->{colors}{yellow} = $image->{GD}->colorAllocate(255,255,0);
		$image->{colors}{green} = $image->{GD}->colorAllocate(0,162,11);
		$image->{colors}{darkgrey} = $image->{GD}->colorAllocate(127,127,127);
		$image->{colors}{grey} = $image->{GD}->colorAllocate(215,215,215);
		$image->{colors}{grey90} = $image->{GD}->colorAllocate(229,229,229);
		$image->{colors}{brown} = $image->{GD}->colorAllocate(161,103,62);
		$image->{colors}{orange} = $image->{GD}->colorAllocate(250,150,5);
	}
	
	bless $image, $class;
		
	return $image;
}

1;
__END__

=head1 NAME

Image::BoxModel - Module for defining boxes on an image an putting things on them

=head1 SYNOPSIS

 use Image::BoxModel;
  
 #Define an object
 my  $image = new Image::BoxModel (
	width => 800, 
	height => 400, 
	lib=> "GD", 			#[IM|GD]
	verbose => "1",		#If you want to see which modules and submodules do what. Be prepared to see many messages :-)
 );
				
 #Define a box named "title" on the upper border
 print $image -> Box(position =>"top", height=>120, name=>"title", background =>'red');	

 #Put some rotated text on the "title"-box and demonstrate some options. (verdana.ttf needs to be present in the same directory)
 print $image -> Text(
	box => "title", 
	text=>"Hello World!\nAligned right, positioned in the center (default)\nslightly rotated.", 
	textsize=>"16",
	rotate => "10" , 
	font=> 'verdana.ttf', 
	fill => "yellow", 
	background=>"green", 
	align=>"Right"
 );

 print $image -> Box(position =>"left", width=>200, name=>"text_1", background =>'blue');	
 print $image -> Text(box => "text_1", text =>"This is some more text.\nIt is positioned\nat the \n'North-West'-side\nof it's box.\nThe alignment\ndafaults to\ncenter\n:-)", textsize=> "12", background=>"yellow", position =>"NorthWest");

 print $image -> Text(text => "Some text on the shrinked 'standard-free-box'\nTo understand what this text means, give the documentation a read.",textsize => 12, rotate=> "-30");

 #Save image to file
 $image -> Save(file=> "01_hello_world_$image->{lib}.png");

=cut

=for pod2html
That's what you should get with this little program:<br>
<img src="../examples/01_hello_world_GD.png">

=head1 DESCRIPTION

=head2 OBJECTIVES

Have a way to draw things on images using the same code with different libraries.

Use OO-style design to make the implementation of new library backends (library wrappers) easy. Only Image::Magick and GD present at the moment.

Use a box model to cut the original image into smaller rectangles. Afterwards objects can be drawn onto these boxes.

Make it easy to write wrappers for the basic functionality of the module. Some are under development already, like the Annotate method in ::Text which defines a fitting box and puts text on it.

Make it easy to write wrapper-wrappers like ::Chart (far from being finished), which use basic functionality as well as wrappers.

Make it easy to write wrapper-wrapper-wrappers and wrapper-wrapper-wrapper-wrappers. ;-)

=head2 ANOTHER IMAGING / CHARTING / WHATEVER MODULE?

There are many Charting Modules out there and many Font Modules as well. 
There are many concepts about how to layout elements on an image / page.

This module will try hard to make the life of the user easier and the life of the developer more fun.

It has backends for graphic libraries (and will have more) so that you can draw images using the same code with different libraries.

Example: One user (me ;-) starts writing a perl script which produces some charts. 
Because Image::Magick is common to me, I use it. After some time I find out that GD would be much faster and is able to do everything I need.
I have to rewrite much of my code because GD does many things different from how IM does them.
..And now someone tells me about the Imager-module from the CPAN!

With this module it is (should be) possible to just replace $image->{lib} in the constructor method and keep the rest of the code.

=head2 FUTURE

Charts

More graphic primitives

Vector graphic backend
(The problem is, the module "thinks" in bitmaps, so it is not completely clear to me how to transfer this into vectors..)

Imager backend

Any more ideas?

=head2 QUESTIONS

Would it make sense to be able and cut off nonrectangular boxes? / Would it be desirable to cut off boxes which result in a nonrectangular remaining free space?
(Define a rectangle in the upper left corner. Then the free field would be a concave hexagon. This produces some problems later: defining new boxes / find out if object is in the box)

How to translate the used bitmap model into the vector model? 
In the bitmap model the smallest unit is one pixel, which defines rather a area of the image with a certain size.
In the world of vectors there is no smallest unit (is there?) and a point has no size.


=head2 EXAMPLES

There is a growing set of sample programs in the example/ directory together with their respective images. This should allow you to understand how things work and verify if your copy of the module works as expected.
To ensure they work even if you don't install the module into your system, they use a "use lib ("../lib"); Dunno if this is appropriate.

=head2 SEE:

README for installation & dependencies.

Image::BoxModel::Lowlevel for basic functionality.

Image::BoxModel::Text for direct & save drawing of text.

=head1 CONCEPT (DISCLAIMER)

THE MODULE WILL BE SUBJECT TO CHANGE, I guess.
So does it's interface.
DON'T USE IN PRODUCTION.

=head1 BUGS

oh, please ;-)

A bug at the moment is something that is broken, not something missing. :-)
Bug reports are welcome.


=head1 AUTHOR

Matthias Bloch, <lt>matthias at puffin ch<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by :m)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
