#! /usr/bin/perl

#this is the shortest way to draw a chart.
#it only takes 4 lines of code if you install the module:

#use Image::BoxModel::Chart;
#my $image = new Image::BoxModel::Chart ()
#$image -> Chart (dataset_1 => [6,4,8],	dataset_2 => [1,2,3],);
#Save(file => 'my.png')

#it can be done nicer, anyway:

use lib ("../lib");	#if you don't install the module but just untar & run example

#even if this is a very simple example it has some style! Feel free to delete the following two lines to make this script even simpler.
use strict;
use warnings;

use Image::BoxModel::Chart;

#create a new object.
my $image = new Image::BoxModel::Chart (
	@ARGV			#used to automate via run_all_examples.pl
);	

#draw a simple chart:

print $image -> Chart (
	dataset_1 => [6,4,12],
	dataset_2 => [-3,2,3],
);

#name of png is equal to the perl-file's name (without .pl). 
(my $name = $0) =~ s/\.pl$//;

$image -> Save(file=> $name."_$image->{lib}.png");
