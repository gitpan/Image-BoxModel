#! /usr/bin/perl;

use strict;
use warnings;

#This script runs all .pl scripts in this folder with all specified libraries.
#I use it to test if the code does what it is meant to do.

my @all_files = glob ("*.pl");
my @libs = ("IM", "GD");

foreach my $file (@all_files){		#all files are processed
	next if ($file eq __FILE__);	#to skip this .pl (we don't want to run ourselves..)
	print "***\n$file\n***\n";
	
	foreach my $lib (@libs){	#for each file all libraries are processed
		print "$lib\n---\n";
		
		print `perl $file lib $lib`;#backticks execute the file and pass lib=>$lib as arguments. 
						#(the output of the command is printed to see what the files would normally print.)
						#(the arguments are simply a flat list which the programs interpolate into a hash, key / value interchangeably)
		print "---\n";
	}
}
