#! /usr/bin/perl

use lib ("../lib");	#if you don't install the module but just untar & run example

use strict;
use warnings;

use Image::BoxModel;

my $image = new Image::BoxModel (
	width => 800, 
	height => 400, 
	lib=> "IM", 			#[IM|GD]
	verbose =>0,
	@ARGV			#used to automate via run_all_examples.pl
					#If you pass arguments directly from the command line be aware that there is no error-checking!
);	

print $image -> Annotate (text=> 'Hello naked BarChart', padding_top=>10, padding_bottom=> 20, background => "white");

print $image -> Annotate (text => "happiness", textsize => 14, box_position => "left", rotate=>-90, padding_right => "10", text_position => "Center");

$image -> ChartBars (values => [1,5,3,10,-10]);

$image -> Save(file=> "20_chart_bars_naked_$image->{lib}.png");