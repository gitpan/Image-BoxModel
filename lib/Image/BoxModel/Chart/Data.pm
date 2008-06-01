package Image::BoxModel::Chart::Data;

use warnings;
use strict;

=head1 NAME

Image::BoxModel::Chart::Data - Data manipulation and analysis methods for Image::BoxModel::Chart

=head1 SYNOPSIS

  For an example and general information see Image::BoxModel::Chart.pm

=head1 DESCRIPTION

Image::BoxModel::Chart::Data implements methods for data manipulation and analysis.

=head2 Methods

=head3 ArrayHeighestLowest

  ($highest, $lowest) = $image-> ArrayHeighestLowest(@array)  

Feed it an array and get the highest and the lowest value of it.

=cut

sub ArrayHighestLowest{
	my $image = shift;
	my @array = @_;
	
	@array = sort {$a <=> $b} @array;
	my $highest = $array[-1];
	my $lowest = $array[0];
	
	return $highest, $lowest;
}

=head3 ArrayHighestWidest

 ($highest_text_size, $widest_text_size) = ArrayHighestWidest(values => [@values], textsize => $textsize, rotate => $rotate in degrees)

Feed it an array of numbers or text and get how much space the largest value needs.

=cut

sub ArrayHighestWidest{
	my $image = shift;
	my %p = @_;
	
	my $widest  = 0;
	my $highest = 0;
	foreach (@{$p{values}}){	
		#~ print "$_\n";
		my ($width, $height) = $image -> GetTextSize(text => $_, textsize => $p{textsize}, rotate => $p{rotate});
		$widest = $width if ($width > $widest);
		$highest = $height if ($height > $highest);
	}
	return $highest, $widest;
}

=head3 ExpandToGrid

 $value_on_grid = $image -> ExpandToGrid (value => $value, skip => $skip, base_line => $base_line);

=cut

sub ExpandToGrid{
	my $image = shift;
	my %p = @_;
	my $step;	#if we step upwards or downwards
	my $counter = 0;
	
	if ($p{value} > $p{base}){
		$step = $p{skip};
		$counter++ while ($step * $counter + $p{base} < $p{value});	#0 * step .. 1 * step until bigger than the value (normally the highest of the array..)
	}
	elsif ($p{value} < $p{base}){
		$step = -$p{skip};
		$counter++ while ($step * $counter + $p{base} > $p{value});
	}
	else {
		return $p{value};	#if the given value equals to the base line, no expansion is needed.
	}
	
	$p{value} = $step * $counter + $p{base}; 
	
	return $p{value};
}

=head3 BuildScaleArray

  my @scale_annotations = BuildScaleArray(lowest => $p{lowest}, highest => $p{highest}, base_line => $p{base_line}, skip => $p{scale_skip});

=cut

sub BuildScaleArray{
	my $image = shift;
	my %p = @_;
	my @scale_array;
	my $counter = 1;
	
	push @scale_array, $p{base};		#First, base goes into @array: Ensure it to be in @array!
	
								#then, all values lower than base_line are prepended
	while ((-$p{skip}) * $counter + $p{base} >= $p{lowest}){
		unshift @scale_array, (-$p{skip}) * $counter + $p{base};
		$counter ++;
	}
	
								#and then, all values bigger than base_line are appended
	$counter = 1;
	while ($p{skip} * $counter + $p{base} <= $p{highest}){
		push @scale_array, $p{skip} * $counter + $p{base};
		$counter ++;
	}
	
	#this seems quite ugly and long. It ensures that the exact value of base is in the array 
	#and it makes it easily possible to do multiplications instead of continued addition, 
	#which might lead to increasing errors if skip holds a value which is not precisely representable. 0.1 e.g.
	#I don't know how precise perl calculates and if this approach improves the results, btw..
	return @scale_array;
}

sub PopulateArrays{
	my $image = shift;
	my %p = @_;
	
	my (@datasets, @colors, @bordercolors);	#@values is always an 2d-array holding the data-sets.
	my $counter = 0;
	my $max_values = 0;
	foreach (sort keys %p){
		next unless (/^dataset/);
		$datasets[$counter] = $p{$_};
		
		my $c = $_ ;	
		$c=~ s/^dataset/color/;	#values_01 becomes color_01
		$colors[$counter] = $p{$c} or $colors[$counter] = $p{color}[$counter] or $colors[$counter] = $p{color}[0];
		
		my ($h, $l) = $image->ArrayHighestLowest(@{$datasets[$counter]});
		$p{highest} = $h unless (exists $p{highest} and $p{highest} > $h);
		$p{lowest} = $l unless (exists $p{lowest} and $p{lowest} < $l);
		$max_values = scalar (@{$datasets[$counter]}) unless ($max_values and $max_values > @{$datasets[$counter]});
		
		$counter ++;
	}
	return (\@datasets, \@colors, \@bordercolors, $max_values, %p);
}

1;
