package Image::BoxModel::Chart;

use warnings;
use strict;
use Image::BoxModel::Chart::Data;
use Image::BoxModel;

use POSIX;
our @ISA = ("Image::BoxModel::Chart::Data", "Image::BoxModel");

=head1 NAME

Image::BoxModel::Chart - Charts using Image::BoxModel (Incomplete)

=head1 SYNOPSIS

 use Image::BoxModel::Chart;
 
 my $image = new Image::BoxModel::Chart (
	width => 800, 
	height => 400, 
	lib=> "GD", 			#your backend
 );	
 #all parameters are optional!
 
 $image -> ChartBars (values => [1,5,3,10,-10]);
 
 $image -> Save(file=> "chart.png");

=head1 DESCRIPTION

Image::BoxModel::Chart will implement different sorts of charts.

bars, points, stapled points, lines

=head2 Methods

=head3 Chart

 $image -> Chart(
	values => \@values|[value1, value2, value3...], 
	
 );

Draw chart. Documentation is incomplete because the interface is due to frequent changes.

=cut

sub Chart{
	my $image = shift;
	my %p = (
		box => 'free',
		
		style => 'bar',
		
		orientation => 'vertical',
		
		scale_annotation_size       => 12,
		scale_annotation_rotate     => 0,
		scale_skip                  => 1,
		scale_annotation_show       => 1,
		scale_position              => 'left',
		scale_annotation_background => $image->{background},
		scale_annotation_padding    => '10',
		
		values_annotation_size       => 12,
		values_annotation_show       => 1,
		values_annotation_position   => 'bottom',
		values_annotation_background => $image->{background},
		values_annotation_padding    => '10',
		values_annotation_rotate     => '-90',
		
		box_border       => 0,
		box              => 'free',
		color            => $image-> DefaultColors(),
		border_color     => "black",
		border_thickness => 1, 
		background_color => 'grey90',
		grid_color       => 'grey50',
		bar_thickness    => ".5",	#how much breakfast the bars have had: 1 = touching each other, .5 = half as thick , >1 overlapping, etc. (bug! paints out of its box if >1!); 0.01 or something for debug (exact positioning..)
		rotate           => 0,
		draw_from_base   => 1,		#if the bars should be drawn from the base or not
		base             => 0,		#"normally" one would like to draw the bars from zero upwards or downwards (negative values), but possibly someone wants to draw from 5 e.g.
		
		@_
	);
	
	my ($max_values, $dataset_ref, $colors_ref, $border_colors_ref);
	($dataset_ref, $colors_ref, $border_colors_ref, $max_values, %p) = $image -> PopulateArrays(%p);
	my @datasets = @{$dataset_ref};
	my @colors = @{$colors_ref};
	my @border_colors = @{$border_colors_ref};
	
	return "Mandatory parameter 'values.+' not specified. Howto call value-parameters: values[any_character_or_number]. No chart drawn.\n" unless @datasets;
	return "Scale_skip must not be 0. Can't draw chart.\n" unless $p{scale_skip};
	
	#change this as soon as orientation 'horizontal' is implemented
	return "Sorry, orientation $p{orientation} unimplemented" unless ($p{orientation} =~ /vertical/i);
	
	#~ return "box_border must be > 0. No chart drawn.\n" unless $p{box_border} > 0;
	
	unless ($p{values_annotations}){	#if there are no values-annotations we just guess and set them to 1,2,3,..
		$p{values_annotations}[$_] = $_+1 foreach (0..$max_values);
	}
		
	if ($p{scale_expand_to_grid}){	#expand highest&lowest to ensure that the chart ends at a value which is printed (if desired :-)
		$p{highest} = $image-> ExpandToGrid (value => $p{highest}, skip => $p{scale_skip}, base => $p{base});
		$p{lowest}  = $image-> ExpandToGrid (value => $p{lowest},  skip => $p{scale_skip}, base => $p{base});
	}

	my @scale_array = $image->BuildScaleArray (base => $p{base}, highest => $p{highest}, lowest => $p{lowest}, skip => $p{scale_skip});
	
	$p{lowest} = $scale_array[0] if ($p{lowest} > $scale_array[0]);		#if base is lower than the lowest value, we need to set lowest to base. (BuilsScaleArray includes base)
	
	#if the chart lives in the topmost box of the image it needs some free space at the top, otherwise the scale annotation (or whatever) wouldn't fit into the picture..
	if ($image->{$p{box}}{top} == 0){
		if ($p{orientation} =~ /vertical/i){
			$image -> Box (
				resize 	=> $p{box},
				height 	=> $p{scale_annotation_size}/2,	#half the size of the scale_annotation should be ok.
				position=> 'top',
				name 	=> "$p{box}_auto_padding_top",
				background=> $image -> {background}
			);
		}
		else{
			#unimplemented
		}
	}
	
	#..and here the same for if chart touches bottom
	if ($image -> {$p{box}}{bottom} == $image->{height}){
		if ($p{orientation} =~ /vertical/i){
			$image -> Box (
				resize 	=> $p{box},
				height 	=> $p{scale_annotation_size}/2,	#half the size of the scale_annotation should be ok.
				position=> 'bottom',
				name 	=> "$p{box}_auto_padding_bottom",
				background=> $image -> {background}
			);
		}
		else{
			#unimplemented
		}
	}
	$p{highest} = $scale_array[-1] if ($p{highest} < $scale_array[-1]);	#and the same for highest
	
	#boxes for scale-annotation
	if ($p{scale_annotation_show}){
		$image -> ArrayBox (
			values_ref 	=> \@scale_array, 
			textsize 	=> $p{scale_annotation_size}, 
			rotate		=> $p{scale_annotation_rotate}, 
			resize 		=> $p{box}, 
			position	=> $p{scale_position},
			name		=> "$p{box}_scale_annotation", 
			background 	=> $p{scale_annotation_background},
		);
		
		$image -> Box(
			resize 		=> $p{box}, 
			position 	=> $p{scale_position}, 
			width		=> $p{scale_annotation_padding}, 
			height 		=> $p{scale_annotation_padding}, 
			name		=> "$p{box}_scale_annotation_padding",
			background 	=> $image ->{background}
		) if $p{scale_annotation_padding};
	}
	
	#boxes for values_annotation
	if ($p{values_annotation_show}){
		$image -> ArrayBox (
			values_ref 	=> $p{values_annotations},
			textsize 	=> $p{values_annotation_size}, 
			rotate		=> $p{values_annotation_rotate}, 
			resize		=> $p{box}, 
			position 	=> $p{values_annotation_position},
			name		=> "$p{box}_values_annotation", 
			background 	=> $p{values_annotation_background},
		);
		$image -> Box(
			resize     => $p{box}, 
			position   => $p{values_annotation_position}, 
			width      => $p{values_annotation_padding}, 
			height     => $p{values_annotation_padding}, 
			name       => "$p{box}_values_annotation_padding",
			background => $image ->{background}
		) if $p{values_annotation_padding};
	}
	
	#after the steps are calculated, lets draw the annotations
	if ($p{scale_annotation_show}){
		$image -> PrintScale(
			array 		=> \@scale_array,
			textsize 	=> $p{scale_annotation_size},
			rotate 		=> $p{scale_annotation_rotate},
			chart_box 	=> $p{box},
			box 		=> 'scale_annotation',
			box_border 	=> $p{box_border},
		);
	}
	
	if ($p{values_annotation_show}){
		$image -> PrintScale(
			array 		=> $p{values_annotations},
			textsize 	=> $p{values_annotation_size},
			rotate 		=> $p{values_annotation_rotate},
			chart_box 	=> $p{box},
			box 		=> 'values_annotation',
			box_border 	=> $p{box_border},
			orientation => 'horizontal',
		);
	}
	
	$image-> DrawRectangle(	#Draw a nice rectangle around the chart
		left 			=> $image->{$p{box}}{left}, 
		right 			=> $image->{$p{box}}{right}, 
		top 			=> $image->{$p{box}}{top}, 
		bottom 			=> $image->{$p{box}}{bottom}, 
		fill_color 		=> $p{background_color},
		border_color 	=> $p{border_color},
		border_thickness=> $p{border_thickness},
	);
	
	$image -> DrawGrid(\@scale_array, 
		orientation 	=> $p{orientation},
		grid_color 		=> $p{grid_color},
		lowest 			=> $p{lowest},
		highest 		=> $p{highest},
		box_border 		=> $p{box_border},
		border_thickness=> $p{border_thickness},
		box 			=> $p{box}
	);
	
	if ($p{orientation} =~ /vertical/i){
		foreach my $number_of_data_element (0 .. $max_values-1){
			
			#left border of "reserved" space for bars / points etc. of given dataset
			
			my $x_leftmost = where_between(
				pos_min => $image->{$p{box}}{left} - $p{box_border},
				pos_max => $image->{$p{box}}{right} + $p{box_border},
				val_min => 0,
				val_max => $max_values,
				val     => $number_of_data_element +.5 # half a step inside
							- $p{bar_thickness} / 2    # - half of the space for all the bars
			);
			
			my $x_rightmost = where_between(
				pos_min => $image->{$p{box}}{left} - $p{box_border},
				pos_max => $image->{$p{box}}{right} + $p{box_border},
				val_min => 0,
				val_max => $max_values,
				val     => $number_of_data_element +.5 + $p{bar_thickness} / 2  # half a step inside
			);
			
			foreach (0.. $#datasets){
				
				my $x1 = where_between(
					pos_min => $x_leftmost,
					pos_max => $x_rightmost,
					val_min => 0,
					val_max => scalar (@datasets),
					val     => $_
				);
				
				my $x2 = where_between(
					pos_min => $x_leftmost,
					pos_max => $x_rightmost,
					val_min => 0,
					val_max => scalar (@datasets),
					val     => $_+1
				);
				
				$datasets[$_][$number_of_data_element] = $p{base} unless ($datasets[$_][$number_of_data_element]);
				
				my $y1 = where_between (
					pos_min => $image->{$p{box}}{bottom} - $p{box_border},
					pos_max => $image->{$p{box}}{top} + $p{box_border},
					val_min => $p{lowest},
					val_max => $p{highest},
					val     => $datasets[$_][$number_of_data_element]
				);
				
				my $y2;

				if ($p{draw_from_base} == 0){	#if from lowest value, we can draw from the bottom of the box. (more or less..)
					$y2 = $image->{$p{box}}{bottom} - $p{box_border};
				}
				else{						#otherwise we count upwards as many steps as there are from lowest_value to zero
						
					$y2 = where_between (
						pos_min => $image->{$p{box}}{bottom} - $p{box_border},
						pos_max => $image->{$p{box}}{top} + $p{box_border},
						val_min => $p{lowest},
						val_max => $p{highest},
						val     => $p{base} 
					);
				}
				
				if ($p{style} =~ /bar/i){
					$image -> DrawRectangle (
						top 	=> $y1, 
						bottom 	=> $y2, 
						left 	=> $x1, 
						right 	=> $x2, 
						fill_color => $colors[$_], 
						border_color=>$p{border_color}, 
						border_thickness => $p{border_thickness}
					);
				}
				elsif ($p{style} =~ /point/i){
					$image -> DrawCircle (
						top 	=> $y1 - ($x2-$x1)/2, 		#$y1 = y-position of value, $x2-$x1 = width of circle
						bottom 	=> $y1+ ($x2-$x1)/2, 
						left 	=> $x1, right => $x2, 
						fill_color => $colors[$_], 
						border_color=>$p{border_color}, 
						border_thickness => $p{border_thickness}
					);
				}
				else {
					print "Sorry. Style $p{style} is (still) unimplemented.\n";
				}
			}
		}
	}
	elsif ($p{orientation} =~ /horizontal/i){
		print "horizontal $p{style}s unimplemented. sorry";
	}
	else{
		die "Unknown orientation $p{orientation}. Should be 'horizontal' or 'vertical'";
	}
	
	return;
}

sub PrintScale{
	my $image = shift;
	my %p = (
		orientation => 'vertical',
		@_
	);
	
	my $c = 0;
	foreach (@{$p{array}}){
		my ($w, $h) = $image -> GetTextSize(text => $_, textsize => $p{textsize}, rotate => $p{rotate});
		my ($x1, $x2, $y1, $y2);
		
		if ($p{orientation} =~ /vertical/i){
			
			$y1 = where_between(
				pos_min => $image->{$p{chart_box}}{bottom} - $p{box_border},
				pos_max => $image->{$p{chart_box}}{top} + $p{box_border},
				val_min => @{$p{array}}[0],
				val_max => @{$p{array}}[-1],
				val     => $_ 
			) - $h/2;
		
			$y2 = $y1 + $h;
						
			$x1 = int ($image->{"$p{chart_box}_$p{box}"}{right}-$w);	#bad: assumes align = right	
			$x2 =      $image->{"$p{chart_box}_$p{box}"}{right};			
		}
		elsif ($p{orientation} =~ /horizontal/i){
			
			$x1 = where_between(
				pos_min => $image->{$p{chart_box}}{left} - $p{box_border},
				pos_max => $image->{$p{chart_box}}{right} + $p{box_border},
				val_min => 0,
				val_max => scalar(@{$p{array}}),
				val     => $c+.5 # half a step inside
			)- $w/2;
			
			$x2 = $x1 + $w;
			
			$y2 = int ($image->{"$p{chart_box}_$p{box}"}{top}+$h);	#bad: assumes align = right); 
			$y1 =      $image->{"$p{chart_box}_$p{box}"}{top};
		}
		else{
			Carp::confess ("bad parameter orientation '$p{orientation}'");
		}		
		
		print $image -> FloatBox(name => "$p{box}_$c", top => $y1, bottom => $y2, right => $x2, left => $x1); 
		print $image -> Text (box=> "$p{box}_$c", text => $_, textsize => $p{textsize}, rotate => $p{rotate});
		$c++;
	}
}

sub DrawGrid{
	my $image = shift;
	my $ref_scale_array = shift;
	my @scale_array = @{$ref_scale_array};
	my %p = @_;
	
	if ($p{orientation} =~ /vertical/){	
		foreach (@scale_array){

			my $y = where_between (
				pos_min => $image->{$p{box}}{top} + $p{box_border},
				pos_max => $image->{$p{box}}{bottom} - $p{box_border},
				val_min => $p{lowest},
				val_max => $p{highest},
				val     => $_
			);
			
			next unless ($y < $image->{$p{box}}{bottom} and $y > $image->{$p{box}}{top});	#don's draw if the grid is exactly on the border of the whole chart. 
			
			$image -> DrawRectangle (
				top => $y-($p{border_thickness}-1)/2, 		#-1 because otherwise the grid would be too fat, / 2 because it's done twice. Perhaps border_thickness is not the appropriate parameter anyway.
				bottom => $y+ ($p{border_thickness}-1)/2, 
				right => $image->{$p{box}}{right}-$p{border_thickness}, 
				left => $image->{$p{box}}{left}+$p{border_thickness}, 
				color => $p{grid_color}
			);
		}
	}
	else{
		#unimplemented
		print "horizontal grid unimplemented. sorry.";
	}
}

=head3 Chart

 $image -> Legend(
	#mandatory:
	font => 		(path to font file),
	name => 		(name of box in which the legend lives)
	values_annotations => (name of your datasets)
	
	#optional (dafaults preset):
	textsize => 	[number],
	rotate => 		[number], 
	colors => 		(color names of datasets), 	#nice: 'colors => DefaultColors()' sets default colors
	position => 	['right'|'left],
	orientation => 	'vertical',					#horizontal is unimplemented so far
	resize => 		(name of box to be resized),
	background => 	(color),
	
	padding_left => [number],
	padding_right =>[number],
	padding_top => 	[number],
	padding_bottom =>[number],
	
	spacing_left => [number],
	spacing_top => 	[number],
	spacing_right =>[number],
	spacing_bottom => [number],
	
	border => 		[number],
	border_color => (color),
 );

Draw Legend. 

=cut

sub Legend{
	my $image = shift;
	my %p = (
		textsize => 12,
		rotate => 0, 
		colors => DefaultColors(),
		position => 'right',
		orientation => 'vertical',
		resize => 'free',
		background => $image->{background},
		
		padding_left => 10,
		padding_right => 10,
		padding_top => 10,
		padding_bottom => 10,
		
		spacing_left => 10,
		spacing_top => 10,
		spacing_right => 10,
		spacing_bottom => 10,
		
		border => 1,
		border_color => 'black',
		
		@_
	);
	
	if (exists $p{values_annotations} and $p{values_annotations}){
		$p{values_ref} = $p{values_annotations};
	}
	else{
		die __PACKAGE__, ": Mandatory parameter 'values_annotations' missing";
	}
	
	die __PACKAGE__, ": Mandatory parameter 'name' missing" unless (exists $p{name} and $p{name});
	
	my $square_size = int ($p{textsize} * .8);	#to be done by some intelligently set parameters..
	
	my ($w, $h) = $image -> ArrayBox (%p, no_box => 1);
	
	#idea: have a big box into which the smaller boxes for legend etc go.
	
	$image -> Box (
		name => "$p{name}",
		width => $p{padding_left} + $p{border} + $p{spacing_left} + $square_size + $p{spacing_left} + $w + $p{spacing_right} + $p{border} + $p{padding_right}+6,
		height => $p{padding_top} + $p{border} + $p{spacing_top} + $h + $p{spacing_bottom} + $p{border} + $p{padding_bottom}+4,
			#+6 / 4: each box needs +1 pixel than thought. grr.
		position => $p{position},
		resize => $p{resize},
	);
	
	foreach ('left', 'right', 'top', 'bottom'){	#padding: 4 little (big) boxes outside the border, one at each corner
		$image -> Box (
			resize => "$p{name}",
			width => $p{"padding_$_"},
			height => $p{"padding_$_"},
			name => "$p{name}_padding_$_",
			position => "$_"
		);
	}
	
	foreach ('left', 'right', 'top', 'bottom'){	#spacing: 4 little (big) boxes inside the border, one at each corner
		$image -> Box (
			resize => "$p{name}",
			width => $p{"spacing_$_"} + $p{border},	#to reserve space for the border as well..
			height => $p{"spacing_$_"} + $p{border},
			name => "$p{name}_spacing_$_",
			position => "$_",
		);
	}
	
	$image -> ArrayBox (		#reserve space for the text
		resize => $p{name},
		name => "$p{name}_text",
		background => $p{background},
		position => $p{position},
		orientation => $p{orientation},
		values_ref => $p{values_ref},
		textsize => $p{textsize},
		rotate => $p{rotate},
		#~ background => 'red'
	);
	
	print $image -> Box(			#some spacing between text & squares
		resize => $p{name},
		name=> "$p{name}_spacing_text_squares",
		width => $p{spacing_left},
		position => $p{position}
		#~ ,background => 'blue'
	);
	
	print $image -> Box(				#box for squares
		resize => $p{name},
		name=> "$p{name}_squares",
		width => $square_size,
		height => $square_size,
		position => $p{position},
		#~ background => 'green'
	);
	
	$image -> DrawRectangle(		#a rectangle as the border of the legend
		top => $image->{"$p{name}_spacing_top"}{top}, 
		bottom => $image->{"$p{name}_spacing_top"}{top}+ $p{border} * 2 + $p{spacing_top} + $h + $p{spacing_bottom}, 
		left => $image->{"$p{name}_spacing_left"}{left}, 
		right => $image->{"$p{name}_spacing_right"}{right},  
		fill_color => $p{background}, 
		border_color => $p{border_color},
		border_thickness => $p{border}
	)if ($p{border});
		
	my ($legend_width, $legend_height);
	
	foreach (0.. scalar(@{$p{values_ref}})-1){
		#~ print @{$p{colors}}[$_], "\t", @{$p{values_ref}}[$_], "\n";
		
		my ($width, $height) = $image -> GetTextSize(
			text => @{$p{values_ref}}[$_],
			textsize => $p{textsize},
			rotate => $p{rotate}
		);
		
		#there will be a distinction between vertically and horizontally drawn legends as soon as this is implemented
		
		$legend_width = $width if ($width or $legend_width < $width);
		$legend_height += $height;
		
		my $e = $image -> Annotate(
			resize =>"$p{name}_text",
			text => @{$p{values_ref}}[$_], 
			textsize => $p{textsize},
			align => 'left', 
			text_position => 'west',
			font => $p{font},
			
		);
		
		my $center_of_minibox = ($image->{$e}{top} + $image->{$e}{bottom}) / 2;
		
		$image -> DrawRectangle(
			top => $center_of_minibox - $square_size / 2, 
			bottom => $center_of_minibox + $square_size / 2, 
			#~ top => $image->{$e}{top},
			#~ bottom => $image->{$e}{bottom},
			left => $image->{"$p{name}_squares"}{left}, 
			right => $image->{"$p{name}_squares"}{right},  
			fill_color => @{$p{colors}}[$_], 
			border_color => 'black'
		);
	}
}

sub where_between{#calculates where on a picture a value has to be painted between two points
	my %p = @_;
	
	foreach ('pos_min', 'pos_max', 'val_min', 'val_max', 'val'){
		Carp::croak ("where_between: missing parameter $_") unless (exists $p{$_});
	}
	
	my $position =  (
		$p{pos_min} 					#minimum position 
		+
		($p{pos_max} - $p{pos_min})		#distance between max & min
		*
		
		($p{val} - $p{val_min})			#difference between value and minimum value (numbers, not position!)
		/ 
		($p{val_max} - $p{val_min})		#difference between max & minimum
		#3 lines above result in a factor between 0 an 1, 0 if val = min, 1 if val = max, .5 if val in the middle between the both.
		
		#the distance between max & min (which are pixels or whatsoever) are multiplied by the factor (0-1).
		#this way, the distance between min and position are calculated
		
		#if max < min the result of max-min is negative so that a negative number is added to min. and everybody is happy without any if().
	);
	
	return $position;
}


sub DefaultColors{
	my $image = shift;
	return ['red', 'orange', 'yellow', 'LightGreen', 'green', 'blue', 'DarkBlue', 'DarkRed'];
}

1;