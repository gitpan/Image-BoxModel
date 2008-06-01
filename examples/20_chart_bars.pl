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

$image -> Annotate (text=> 'some friends using this module', padding_top=>10, textsize => 20, padding_bottom=> 20, font => './FreeSans.ttf');

$image -> Annotate (text => "happiness", box_position => "left", rotate=>-90, textsize => 15, padding_right => "10", text_position => "Center", font => './FreeSans.ttf');

$image -> Annotate (text => 'version of Image::BoxModel::Chart', textsize => 15, box_position => "bottom", font => './FreeSans.ttf');

my @a = [7,7,7];

print $image -> ChartBars (
	dataset_00 => @a,
	dataset_01 => [-1,0,5,3,11.5,12], 
	dataset_02 => [5,5,5,5,4,7], 
	dataset_999=> [-3,-2,-1,8,9,10], 
	dataset_foo => [11,11,11,11],	#missing numbers are zerofilled (base-filled, precisely)
	dataset_50 => [1,1,1,1,1,1],
	dataset_51 => [2,2,2,2,2,2],
	dataset_52 => [3,3,3,3,3,3],
	
	border_thickness => 1, 
	#~ color_01=>'orange', 
	#~ border_color => 'red', 
	draw_from_base => 1,			#if the chart should be drawn from the base or not (perl-true / perl-false)
	base => 0,					#from this value the bars are drawn upside and downside. 
	
	scale_skip => 1,
	#~ scale_position => 'right',
	scale_expand_to_grid => 1,
	scale_annotation_rotate => '0',
	scale_annotation_size => '15',
	#~ scale_annotation_background => 'orange',
	
	values_annotations => ['0.01', '0.04', '0.09', '0.10', '0.11', "(future)\nstable\nrelease"],
	#~ values_annotation_background => 'yellow',
	values_annotation_rotate => '-70',
	values_annotation_position => 'bottom',
	values_annotation_size => 15,
	
	legend_show => 1,
	
	font => './FreeSans.ttf'
	
	#~ orientation => 'horizontal',	#unimplemented
);

$image -> Save(file=> "20_chart_bars_$image->{lib}.png");