package Image::BoxModel::Chart;

use warnings;
use strict;
use Image::BoxModel::Chart::Data;
use Image::BoxModel;
our @ISA = ("Image::BoxModel::Chart::Data", "Image::BoxModel");

=head1 NAME

Image::BoxModel::Chart - Charts using Image::BoxModel (Incomplete)

=head1 SYNOPSIS

 use Image::BoxModel::Chart;
 
 my $image = new Image::BoxModel::Chart (
	width => 800, 
	height => 400, 
	lib=> "IM", 			#[IM|GD]
 );	
 
 print $image -> Annotate (text=> 'Hello naked BarChart', padding_top=>10, padding_bottom=> 20, background => "white");
 
 print $image -> Annotate (text => "happiness", textsize => 14, box_position => "left", rotate=>-90, padding_right => "10", text_position => "Center");
 
 $image -> ChartBars (values => [1,5,3,10,-10]);
 
 $image -> Save(file=> "20_chart_bars_naked_$image->{lib}.png");

=head1 DESCRIPTION

Image::BoxModel::Chart will implement different sorts of charts.

bars, points, stapled points, lines; all vertically and horizontally

The development is quite slow, so if you wish to see something implemented, get the source and feel free to contribute. Or consider sponsoring. :-)

Completeness is more important here than a fast implementation.

=head2 Methods

=head3 ChartBars

 $image -> ChartBars(values => \@values|[value1, value2, value3...] scale_skip

Draw naked bars on an empty box.

=cut

sub ChartBars{
	my $image = shift;
	my %p = (
		box => "free",
		scale_skip => 1,
		box_border => 10,
		box => "free",
		color => "red",
		bordercolor => "black",
		dropshadow_bordercolor => "darkgrey",
		dropshadow_color => "grey",
		bar_thickness => ".5",	#how much breakfast the bars have had: 1 = touching each other, .5 = half as thick , >1 overlapping, etc. (bug! paints out of its box if >1!); 0.01 or something for debug (exact positioning..)
		font => "verdana.ttf",
		to_border => 1,	#true if first & last tick are on the border .. I believe this to be crap
		rotate => 0,
		@_
	);
	return "Mandatory parameter 'values' not specified. No chart drawn.\n" unless $p{values};
	my @values = @{$p{values}};
	
	#Determine highest an lowest value.
	($p{highest}, $p{lowest}) = $image ->ArrayHighestLowest(@values);
	
	#expand highest&lowest to ensure that the chart ends at a value which is printed (if desired :-)
	$p{highest} = $image-> ExpandToGrid (value => $p{highest}, skip => $p{scale_skip}, base_line => $p{base_line}) if $p{scale_expand_to_grid};
	$p{lowest}  = $image-> ExpandToGrid (value => $p{lowest},  skip => $p{scale_skip}, base_line => $p{base_line}) if $p{scale_expand_to_grid};
	
	my $counter = 0;
	
	my $x_step = ($image->{$p{box}}{width}- ($p{box_border}-1) *2) / scalar(@values);		#step from the center of one bar / numer to the next
	my $y_step = ($image->{$p{box}}{height} - ($p{box_border}-1) *2) / ($p{highest} - $p{lowest}+1 - $p{to_border});
	my $shift = 0;
	$shift = $y_step / 2 unless ($p{to_border});	#..the 1st tick is painted half a step inside..
	
	foreach (@values){
		my $x1 = int ( $image->{$p{box}}{left}+ $x_step * $counter + $x_step / 2 - $p{bar_thickness}* $x_step / 2 +$p{box_border}-1);	#round properly?
		my $x2 = int ( $image->{$p{box}}{left}+ $x_step * $counter + $x_step / 2 + $p{bar_thickness}* $x_step / 2 +$p{box_border}-1);
		my $y1 = int ( $image->{$p{box}}{bottom}- $y_step * ($_ - $p{lowest}) - $shift  - $p{box_border}+1);
		my $y2 = int ( $image->{$p{box}}{bottom} - $p{box_border}+1);	#feature to be added: wheter we paint from the bottom or from zero.
		$counter ++;
		next if ($_ == $p{lowest});	#not very clever: as soon as "draw from zero" is added, this has to be changed.
		
		$image -> DrawRectangle (top => $y1, bottom => $y2, left => $x1, right => $x2, fill_color => $p{color}, border_color=>$p{bordercolor});
	}
	return;
}

=head3 Chart

Incomplete! Don't use!

It fights the problem from outside an will be cutting boxes for axis-annotations, ticks and so on. I will first fight from the inside and do the "naked" charts. Afterwards I will come back and fix this.

=cut

#Chart has to be changed: It should first cut off scale-annotation, padding, tick, then value-annotation. 
#Then we need a new method to put ticks & text on scale-annotation relative to the borders of the chart-field..
#Anyway, the effort is not for nothing, because the methods in ::Data can & will be used. :-)

sub Chart{
	my $image = shift;
	my %p = preset_defaults(@_);
	return "Mandatory parameter 'values' not specified. No chart drawn.\n" unless $p{values};

	#Check if desired box to put chart on is present
		#please implement
		
	#Check if scale-position makes sense. "Bottom" if chart is "vertical" is nonsense e.g.
		#please implement
	
	#Determine highest an lowest value.
	($p{highest}, $p{lowest}) = $image ->ArrayHighestLowest(@{$p{values}});
	
	#expand highest&lowest to ensure that the chart ends at a value which is printed (if desired :-)
	$p{highest} = $image-> ExpandToGrid (value => $p{highest}, skip => $p{scale_skip}, base_line => $p{base_line}) if $p{scale_expand_to_grid};
	$p{lowest}  = $image-> ExpandToGrid (value => $p{lowest},  skip => $p{scale_skip}, base_line => $p{base_line}) if $p{scale_expand_to_grid};
	
	#Find the chart a free name for its box (unless the user gave it one..)
		#please implement!
	
	#scale-annotation
	if ($p{scale_annotation_show}){
		
		#Build array of scale-annotations: -10, -8, -6 ... 16, 18, 20 e.g.
		my @scale_annotations = $image -> BuildScaleArray(lowest => $p{lowest}, highest => $p{highest}, base_line => $p{base_line}, skip => $p{scale_skip});
		
		#~ print join ("\n", @scale_annotations);
		
		#Determine widest and highest annotation
		($p{scale_height}, $p{scale_width}) = $image-> ArrayHighestWidest(values=> $p{values}, textsize => $p{scale_annotation_size}, rotate => $p{scale_annotation_rotate});
		
		#reserve space for scale-annotation
		print $image -> Box(
			resize => $p{name}, 
			position =>$p{scale_position}, 
			width=> $p{scale_width}, 
			height => $p{scale_height}, 	#the good thing is, box only uses the value it needs. if it makes a new box on the left, height is ignored.
			name=> "$p{name}_scale_annotation", 
			background => $p{scale_annotation_background}
		);
		print $image -> Box(
			resize => $p{name}, 
			position =>$p{scale_position}, 
			width=> $p{scale_annotation_padding}, 
			height =>$p{scale_annotation_padding}, 
			name=> "$p{box}_scale_annotation_padding",
			background => $p{scale_padding_background}
		) if $p{scale_annotation_padding};
		
		#make little boxes for each number in @scale_annotations
		$image -> BoxSplit (box => "$p{name}_scale_annotation", orientation=> "vertical", count => scalar(@scale_annotations));
		
		#print scale-annotation
			#orientation (left etc) is unimplemented)
		my $counter = 0;
		foreach (@scale_annotations){
			print "Hello $_\n";
			print $image -> Text (
				box => "$p{name}_scale_annotation_$counter",	#the little boxes have the names $p{name}_scale_annotation_0, $p{name}_scale_annotation_1 ...
				textsize => $p{scale_annotation_size},
				rotate => $p{scale_annotation_rotate},
				text => $_
			);
			$counter ++;
		}
	}
	
	#values-annotation
	if ($p{values_annotation_show}){
		
	}
	
	return;	#nothing at the moment!
}



=head2 Internal methods

=head3 preset_defaults

Sets many standard values so that the user does not need to specify them. Serves as a source of information if you want to know the possibilities..

While this changes more often than it remains the same, please see the source! I will add the pod as soon as the interface is more or less stable.

=cut

sub preset_defaults{
	my %p =(
		name => "free",					#name of the box to put chart on.
	
		scale_skip => 1,
		base_line => 0,					#From here bars or whatever are drawn. If it is =0, negative numbers are drawn downwards e.g.
		
		#on vertical charts the vertical axis is named scale. To avoid confusion on horizontal charts where the horizontal axis is 'scale'
		scale_expand_to_grid => 1,			#If the chart starts and ends at a "grid-value"
		scale_annotation_show => 1,			#If the chart has a scale at one side (normally left; horizontal charts would be top or bottom)
		scale_annotation_size => 22,
		scale_annotation_rotate => 0,
		scale_annotation_background => "white",
		scale_annotation_padding => 0,
		scale_padding_background => "white",
		
		scale_position => "left",
		
		#correspondingly, the horizontal axis on vertical charts is 'values'. Any better proposals?
		values_annotation_show => 1,
		
		#unused from here:
		box => "free",
		
		
		
		scale_tick_lenght => 0,
		scale_tick_background => "white",
		scale_to_border => 0,
		
		bars => "no",
		bars_text_size => 22,
		bars_text_rotate => 0,
		bars_text_background => "white",
		bars_text_padding => 0,
		bars_text_position => "Center",
		bars_tick_background => "white",
		bars_skip =>1,
		style => "bars", #nothing else at the moment :-(
		@_
	);
	return %p;
}

1;