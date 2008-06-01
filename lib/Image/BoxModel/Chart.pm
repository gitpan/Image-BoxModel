package Image::BoxModel::Chart;

use warnings;
use strict;
use Image::BoxModel::Chart::Data;
use Image::BoxModel;

#~ use POSIX;
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

The development is quite slow here, so if you wish to see something implemented, get the source and feel free to contribute. Or consider sponsoring. :-)

=head2 Methods

=head3 ChartBars

 $image -> ChartBars(
	values => \@values|[value1, value2, value3...], 
	scale_skip => [number]	#skip on scale-axis

Draw naked bars on an empty box.

=cut

sub ChartBars{
	my $image = shift;
	my %p = (
		box => 'free',
		
		orientation => 'vertical',
		
		scale_annotation_size => 12,
		scale_annotation_rotate => 0,
		scale_skip => 1,
		scale_annotation_show => 1,
		scale_position => 'left',
		scale_annotation_background => $image->{background},
		scale_annotation_padding => '10',
		
		values_annotation_size => 12,
		values_annotation_show => 1,
		values_annotation_position => 'bottom',
		values_annotation_background => $image->{background},
		values_annotation_padding => '10',
		values_annotation_rotate => '-90',
		
		box_border => 10,
		box => 'free',
		color => ['red', 'orange', 'yellow', 'LightGreen', 'green', 'blue', 'DarkBlue', 'DarkRed'],
		border_color => "black",
		border_thickness => 1, 
		background_color => 'grey90',
		grid_color => 'grey50',
		bar_thickness => ".5",	#how much breakfast the bars have had: 1 = touching each other, .5 = half as thick , >1 overlapping, etc. (bug! paints out of its box if >1!); 0.01 or something for debug (exact positioning..)
		to_border => 1,	#true if first & last tick are on the border .. I believe this to be crap
		rotate => 0,
		draw_from_base => 0,	#if the bars should be drawn from the base or not
		base => 0,		#"normally" one would like to draw the bars from zero upwards or downwards (negative values), but possibly someone wants to draw from 5 e.g.
		
		legend_show => 0,
		legend_position => 'right',
		legend_background => $image->{background},
		legend_padding => 10,
		legend_border => 1,
		
		@_
	);
	
	my ($max_values, $dataset_ref, $colors_ref, $border_colors_ref);
	($dataset_ref, $colors_ref, $border_colors_ref, $max_values, %p) = $image -> PopulateArrays(%p);
	my @datasets = @{$dataset_ref};
	my @colors = @{$colors_ref};
	my @border_colors = @{$border_colors_ref};
	
	return "Mandatory parameter 'values.+' not specified. Howto call value-parameters: values[any_character_or_number].  No chart drawn.\n" unless @datasets;
	return "Scale_skip must not be 0. Can't draw chart" unless $p{scale_skip};
		
	if ($p{scale_expand_to_grid}){	#expand highest&lowest to ensure that the chart ends at a value which is printed (if desired :-)
		$p{highest} = $image-> ExpandToGrid (value => $p{highest}, skip => $p{scale_skip}, base => $p{base});
		$p{lowest}  = $image-> ExpandToGrid (value => $p{lowest},  skip => $p{scale_skip}, base => $p{base});
	}

	my @scale_array = $image->BuildScaleArray (base => $p{base}, highest => $p{highest}, lowest => $p{lowest}, skip => $p{scale_skip});
	
	$p{lowest} = $scale_array[0] if ($p{lowest} > $scale_array[0]);		#if base is lower than the lowest value, we need to set lowest to base. (BuilsScaleArray includes base)
	$p{highest} = $scale_array[-1] if ($p{highest} < $scale_array[-1]);	#and the same for highest
	
	#boxes for scale-annotation
	if ($p{scale_annotation_show}){
		$image -> ArrayBox (
			%p, 
			values_ref => \@scale_array, 
			textsize => $p{scale_annotation_size}, 
			rotate=>$p{scale_annotation_rotate}, 
			resize => $p{box}, 
			position => $p{scale_position},
			name=> "$p{box}_scale_annotation", 
			background => $p{scale_annotation_background},
		);
		
		$image -> Box(
			resize => $p{box}, 
			position =>$p{scale_position}, 
			width=> $p{scale_annotation_padding}, 
			height =>$p{scale_annotation_padding}, 
			name=> "$p{box}_scale_annotation_padding",
			background => $image ->{background}
		) if $p{scale_annotation_padding};
	}
	
	#boxes for values_annotation
	if ($p{values_annotation_show}){
		$image -> ArrayBox (
			%p,
			values_ref => $p{values_annotations},
			textsize => $p{values_annotation_size}, 
			rotate=>$p{values_annotation_rotate}, 
			resize => $p{box}, 
			position => $p{values_annotation_position},
			name=> "$p{box}_values_annotation", 
			background => $p{values_annotation_background},
		);
		$image -> Box(
			resize => $p{box}, 
			position =>$p{values_annotation_position}, 
			width=> $p{values_annotation_padding}, 
			height =>$p{values_annotation_padding}, 
			name=> "$p{box}_values_annotation_padding",
			background => $image ->{background}
		) if $p{values_annotation_padding};
	}
	
	if ($p{legend_show}){
		$image -> Legend(
			colors => \@colors, 
			values_ref => $p{values_annotations},
			textsize => $p{values_annotation_size}, 
			#~ rotate=>$p{values_annotation_rotate}, 
			resize => $p{box}, 
			position => $p{legend_position},
			name => "$p{box}_legend",
			background => $p{legend_background},
			padding => $p{legend_padding},
			font => $p{font},
			border => $p{legend_border},
		);
		$image -> Box(
			resize => $p{box}, 
			position =>$p{legend_position}, 
			width=> $p{legend_padding}, 
			height =>$p{legend_padding}, 
			name=> "$p{box}_legend_padding",
			background => $image ->{background}
		) if $p{values_annotation_padding};
	}
	
	my $x_step = ($image->{$p{box}}{width}- ($p{box_border}-1) *2) / $max_values;		#step from the center of one bar / number of bars to the next
	my $y_step = ($image->{$p{box}}{height} - ($p{box_border}-1) *2) / ($p{highest} - $p{lowest}+1 - $p{to_border});
	my $shift = 0;
	$shift = $y_step / 2 unless ($p{to_border});	#..the 1st tick is painted half a step inside..
	
	#after the steps are calculated, lets draw the annotations
	if ($p{scale_annotation_show}){
		my $c = 0;
		foreach (@scale_array){
			my ($w, $h) = $image -> GetTextSize(text => $_, textsize => $p{scale_annotation_size}, rotate => $p{scale_annotation_rotate});
			
			my $y = int ($image->{$p{box}}{bottom}- $y_step * ($_ - $p{lowest}) - $shift  - $p{box_border}+1);
			
			my $x1 = int ($image->{"$p{box}_scale_annotation"}{right}-$w);	#bad: assumes align = right	
			my $x2 = $image->{"$p{box}_scale_annotation"}{right};

			print $image -> FloatBox(name => "scale_annotation_$c", top => ($y - $h/2), bottom => ($y + $h/2), right => $x2, left => $x1); 
			print $image -> Text (box=> "scale_annotation_$c", text => $_, textsize => $p{scale_annotation_size}, rotate => $p{scale_annotation_rotate});
			$c++;
		}
	}
	
	if ($p{values_annotation_show}){
		my $c = 0;
		foreach (0.. scalar(@{$p{values_annotations}})-1){
			my ($w, $h) = $image -> GetTextSize(text => $p{values_annotations}->[$_], textsize => $p{values_annotation_size}, rotate => $p{values_annotation_rotate});
			
			my $x = int ($image->{$p{box}}{left}+ $x_step * $_ + $x_step / 2 +$p{box_border}-1);
			
			my $y1 =  $image->{"$p{box}_values_annotation"}{top}+$h;	#bad: assumes align = right); 
			my $y2 = $image->{"$p{box}_values_annotation"}{top};
			
			print $image -> FloatBox(name => "values_annotation_$c", top => $y2, bottom => $y1, left => ($x-$w/2), right => ($x+$w/2));
			print $image -> Text (box => "values_annotation_$c", text => @{$p{values_annotations}}[$_], textsize => $p{values_annotation_size}, rotate => $p{values_annotation_rotate});
			$c++;
		}
	}
	
	$image-> DrawRectangle(	#Draw a nice rectangle around the chart
		left => $image->{$p{box}}{left}, 
		right => $image->{$p{box}}{right}, 
		top => $image->{$p{box}}{top}, 
		bottom => $image->{$p{box}}{bottom}, 
		fill_color => $p{background_color},
		border_color => $p{border_color},
		border_thickness => $p{border_thickness},
	);
	
	$image -> DrawGrid(\@scale_array, $y_step, $shift, %p);
	
	foreach my $number_of_data_element (0 .. $max_values-1){
		my $x_leftmost = int ( $image->{$p{box}}{left}+ $x_step * $number_of_data_element + $x_step / 2 - $p{bar_thickness}* $x_step / 2 +$p{box_border}-1);	#round properly?
		my $x_rightmost = int ( $image->{$p{box}}{left}+ $x_step * $number_of_data_element + $x_step / 2 + $p{bar_thickness}* $x_step / 2 +$p{box_border}-1);
		
		foreach (0.. $#datasets){
			my $x1 = int ($x_leftmost + ($x_rightmost - $x_leftmost) / scalar(@datasets) * $_);
			my $x2 = int ($x_leftmost + ($x_rightmost - $x_leftmost) / scalar(@datasets) * ($_+1));
			$datasets[$_][$number_of_data_element] = $p{base} unless ($datasets[$_][$number_of_data_element]);
			my $y1 = int ( $image->{$p{box}}{bottom}- $y_step * ($datasets[$_][$number_of_data_element] - $p{lowest}) - $shift  - $p{box_border}+1);
			
			my $y2;
			if ($p{draw_from_base} == 0){	#if from lowest value, we can draw from the bottom of the box. (more or less..)
				$y2 = int ( $image->{$p{box}}{bottom} - $p{box_border}+1);
			}
			else{						#otherwise we count upwards as many steps as there are from lowest_value to zero
				$y2 = int ( $image->{$p{box}}{bottom} - $y_step * ($p{base} - $p{lowest}) - $shift  - $p{box_border}+1);	
			}
			
			$image -> DrawRectangle (top => $y1, bottom => $y2, left => $x1, right => $x2, fill_color => $colors[$_], border_color=>$p{border_color}, border_thickness => $p{border_thickness});
		}
	}
	
	return;
}

sub DrawGrid{
	my $image = shift;
	my $ref_scale_array = shift;
	my @scale_array = @{$ref_scale_array};
	my $y_step = shift;
	my $shift = shift;
	my %p = @_;
	
	if ($p{orientation} =~ /vertical/){
		foreach (@scale_array){
			my $y = int ($image->{$p{box}}{bottom}- $y_step * ($_ - $p{lowest}) - $shift  - $p{box_border}+1);
			$image -> DrawRectangle (
				top => $y-($p{border_thickness}-1)/2, 		#-1 because otherwise the grid would be too fat, / 2 because it's done twice. Perhaps border_thickness is not the appropriate parameter anyway.
				bottom => $y+ ($p{border_thickness}-1)/2, 
				right => $image->{$p{box}}{right}-$p{border_thickness}, 
				left => $image->{$p{box}}{left}+$p{border_thickness}, 
				color => $p{grid_color});
		}
	}
	else{
		#unimplemented
	}
}

sub Legend{
	my $image = shift;
	my %p = @_;
	
	my $square_size = int ($p{textsize} * .8);	#to be done by some intelligently set parameters..
	my $padding = 5;	#ditto
	
	$image -> ArrayBox (%p);
	$image -> Box(
		%p,
		name=> "$p{resize}_padding",
		width => $padding,
		#~ background => "white"
	);
	$image -> Box(
		%p,
		name=> "$p{resize}_legend_squares",
		width => $square_size,
		#~ background => "orange"
	);
	
	$image -> DrawRectangle(
			top => $image->{$p{name}}{top}, 
			bottom => $image->{$p{name}}{bottom}, 
			left => $image->{"$p{resize}_legend_squares"}{left}, 
			right => $image->{$p{name}}{right},  
			fill_color => $p{background}, 
			border_color => 'black'
		)		if ($p{border});
	
	my ($legend_width, $legend_height);
	
	foreach (0.. scalar(@{$p{values_ref}})-1){
		#~ print @{$p{colors}}[$_], "\t", @{$p{values_ref}}[$_], "\n";
		
		my ($width, $height) = $image -> GetTextSize(
			text => @{$p{values_ref}}[$_],
			textsize => $p{textsize},
			rotate => $p{rotate}
		);
		#~ print "width: $width, height: $height\n";
		
		$legend_width = $width if ($width or $legend_width < $width);
		$legend_height += $height;
		
		my $e = $image -> Annotate(%p, resize =>$p{name}, text => @{$p{values_ref}}[$_], align => 'left', text_position => 'west');
		print "$e: @{$p{values_ref}}[$_]\t top_of_minibox: $image->{$e}{top}\t botton_of_minibox: $image->{$e}{bottom}\n";
		my $center_of_minibox = ($image->{$e}{top} + $image->{$e}{bottom}) / 2;
		
		$image -> DrawRectangle(
			top => $center_of_minibox - $square_size / 2, 
			bottom => $center_of_minibox + $square_size / 2, 
			left => $image->{"$p{resize}_legend_squares"}{left}, 
			right => $image->{"$p{resize}_legend_squares"}{right},  
			fill_color => @{$p{colors}}[$_], 
			border_color => 'black'
		);
	}
	
	print "Size requested for legend: width: $legend_width, height: $legend_height"
	
	
}

1;