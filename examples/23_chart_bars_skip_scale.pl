#! /usr/bin/perl

use lib ("../lib");	#if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel::Chart;

my $image = new Image::BoxModel::Chart (
	width => 800, 
	height => 400, 
	lib=> "GD", 			#[IM|GD]
	verbose =>0,
	background => 'white',
	@ARGV			#used to automate via run_all_examples.pl
					#If you pass arguments directly from the command line be aware that there is no error-checking!
);	

$image -> Annotate (text=> 'Skip Grid and Ticks For Some Values', padding_top=>10, textsize => 20, padding_bottom=> 20, font => './FreeSans.ttf');

$image -> Annotate (text => "High Values", box_position => "left", rotate=>-90, textsize => 20, padding_right => "10", text_position => "Center", font => './FreeSans.ttf');

$image -> Annotate (text => 'Something', textsize => 15, box_position => "bottom", font => './FreeSans.ttf');

print $image -> Chart (
	dataset_00 => [12,	543,	32,		234,	124,	0,		34],
	dataset_01 => [-23,	342,	543.	-500,	-102,	500,	762], 
	
	style => 'bar',					
	
	box_border => 0,				#how far the chart is set inside its grey rectangle
	
	border_thickness => 1, 
	draw_from_base => 1,			#if the chart is to be drawn from the base or not (perl-true / perl-false)
	
	scale_ticks_length => 2,
	values_ticks_length => 10,
	
	#~ scale_skip => 50,			# let's determin scale_skip automagically :-) If you want to specify it, decomment.
	scale_expand_to_grid => 1,
	scale_annotation_rotate => '0',
	scale_annotation_size => '15',
	
	values_annotations => [1,2],
	values_annotation_position => 'bottom',
	values_annotation_size => 15,
	
	font => './FreeSans.ttf',
	
	orientation => 'vertical',	#vertical|horizontal: being implemented
);

$image -> Save(file=> "23_chart_bars_$image->{lib}.png");
