#! /usr/bin/perl;

use lib ("../lib/");	#if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;
  
#Define an object
my  $image = new Image::BoxModel (
	width => 800, 
	height => 400, 
	lib=> "GD", 			#[IM|GD]
	verbose => "0",		#If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV			#used to automate via run_all_examples.pl
					#If you pass arguments directly from the command line be aware that there is no error-checking!
);
				
#Define a box named "title" on the upper border
print $image -> Box(position =>"top", height=>120, name=>"title", background =>'#555555');		#html-style colors

print $image -> Box(position =>"bottom", height=>20, name=>"subtitle", background =>'red');		#human-style colors

#~ #Put some rotated text on the "title"-box and demonstrate some options. (verdana.ttf needs to be present in the same directory)
#~ print $image -> Text(box => "title", text=>"Hello World!\nAligned right, positioned in the center (default)\nslightly rotated.", textsize=>"16",rotate => "10" , font=> 'verdana.ttf', fill => "yellow", background=>"green", align=>"Right");

#~ print $image -> Box(position =>"left", width=>200, name=>"text_1", background =>'blue');	
#~ print $image -> Text(box => "text_1", text =>"This is some more text.\nIt is positioned\nat the \n'North-West'-side\nof it's box.\nThe alignment\ndafaults to\ncenter\n:-)", textsize=> "12", background=>"yellow", position =>"NorthWest");

#~ print $image -> Text(text => "Some text on the shrinked 'standard-free-box'\nTo understand what this text means, give the documentation a read.",textsize => 12, rotate=> "-30");

#Save image to file
$image -> Save(file=> "03_colors_$image->{lib}.png");