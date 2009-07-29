#! /usr/bin/perl;

use lib ("../lib/");	#if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;
  
#Define an object
my $image = new Image::BoxModel (
	width => 800, 
	height => 400, 
	lib=> "GD", 			#[IM|GD]
	fontconfig => 0,		
	#~ verbose => "0",		#If you want to see which modules and submodules do what. Be prepared to see many messages :-)
	@ARGV			#used to automate via run_all_examples.pl
					#If you pass arguments directly from the command line be aware that there is no error-checking!
);

$image -> DrawRectangle(	# a filled rectangle without border
	left 	=> 20,
	top 	=> 20,
	right	=> 100,
	bottom 	=> 100,
	
	color 	=> 'blue',
);

$image -> DrawRectangle(	# a filled rectangle with a border of a different color
	left 	=> 120,
	top 	=> 20,
	right	=> 200,
	bottom 	=> 100,
	
	fill_color 	=> 'blue',
	border_color=> 'red',
	border_thickness => 10,
);

$image -> DrawCircle(		# a circle without border
	left 	=> 220,
	top 	=> 20, 	
	right	=> 300,
	bottom 	=> 100,
	
	color 	=> 'orange',
);

$image -> DrawCircle(		# a circle without a border of a different color
	left 	=> 320,
	top 	=> 20, 	
	right	=> 400,
	bottom 	=> 100,

	fill_color => 'orange', 
	border_color=>'black', 
	border_thickness => 4
);


foreach (400,450,500,550){	# some lines without border
	$image -> DrawLine(
		x1 		=> $_,
		y1		=> 10,
		x2		=> 500,
		y2		=> 100,
		
		color 	=> 'green',
		thickness => 10,
	);
}


(my $name = $0) =~ s/\.pl$//;
#Save image to file
$image -> Save(file=> $name."_$image->{lib}.png");