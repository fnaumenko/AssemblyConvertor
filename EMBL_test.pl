#################################################################
## Convert coordinates between GRCh38 and GRCh37 assemblies,
## using Ensembl Perl API.
## Test for EMBL-EBI performed by Fedor Naumenko 16/07/2020
##
## script arguments:
## arg[0] : string $chromosome
## arg[1] : int	$region source start position
## arg[2] : int $region source end position
## arg[3] : bool $if false then convert from GRCh38 to GRCh37, otherwise the opposite; false by default
## arg[4] : bool $if true then print elapsed time (per operation and total); false by default
## arg[5] : bool $if true then print source and target regions; false by default
#################################################################

#!/bin/perl -w

use Bio::EnsEMBL::Registry;
use DateTime;

## check arguments
@arg_titles = ("chromosome", "region start position", "region end position");
for my $i (0..2) {
	if(!$ARGV[$i]) { print "missed required argument: ", $arg_titles[$i], "\n"; exit; }
}

# default arguments
$ARGV[3] ||= 0;	# if false then convert from GRCh38 to GRCh37, otherwise the opposite
$ARGV[4] ||= 0;	# if true then print elapsed time
$ARGV[5] ||= 0;	# if true then print regions

@db_ports	= (3306, 3337);
@ass_ids	= (38, 37);
$chrom		= $ARGV[0];
$start_pos	= $ARGV[1];
$end_pos	= $ARGV[2];
$src_targ	= $ARGV[3];
$pr_time	= $ARGV[4];
$pr_regn	= $ARGV[5];
$ass_title	= 'GRCh';
$registry	= 'Bio::EnsEMBL::Registry';
$start_time	= time;
$total_start_time = DateTime->now;
$slice_targ;	# early declared becuase of using in sub printCoord
$region;		# early declared becuase of using in sub printCoord

### Print elapsed time
##	arg[1] : string $title
sub printTime {
	if($pr_time) {
		print "$_[0]:\t", time - $start_time, " s\n";
		$start_time = time;
	}
}

### Return slice object of a given genome from DB
##	arg[1] : string $title
sub getSlice {
	$registry->clear();
	$registry->load_registry_from_db(
		-host => 'ensembldb.ensembl.org',
		-user => 'anonymous',
		-species => 'homo sapiens',
		-port => $db_ports[$_[0]]
	);
	printTime("load $ass_title$ass_ids[$_[0]]");
	my $slice_adaptor = $registry->get_adaptor( 'Human', 'Core', 'Slice' );
	return $slice_adaptor->fetch_by_region('chromosome', $chrom);
}

### Print target region coordinates
##	arg[0] : sequence $target sequence
##	arg[1] : int $difference between chrom length for different assamblies
##	return : bool $true if target region was not found
sub printCoord {
	my $loc = index($_[0], $region);	# printTime("get loc");
	if($loc == -1) { return 1; }		# don't find region matched
	if($_[1]) { $loc += $start_pos - $_[1]; }
	else { $loc += 1; }

	my $loc_end_pos = $end_pos + $loc - $start_pos;
	if($pr_regn) {						# print source and target regions
		print "$region\n";
		print $slice_targ->subseq($loc, $loc_end_pos), "\n";
	}

	print "$loc $loc_end_pos\n";		# main result
	if($pr_time) {
		my $elapse = DateTime->now - $total_start_time;
		print "Total time: ".$elapse->minutes().":".$elapse->seconds()." (mm:ss)\n";
	}
	return 0;
}

##### execution ######

print "$ass_title$ass_ids[$src_targ] -> $ass_title$ass_ids[!$src_targ]\n";	# feedback output

## check for source region
if($start_pos < 0 or $end_pos < 0 or $start_pos >= $end_pos) {
	print "Incorrect region's coordinates\n";
	exit;
}

$slice_src = getSlice($src_targ);	# source release from db
## check for chrom length
if($end_pos > $slice_src->end()) {
	print "End of region exceeds chromosome's length ", $slice_src->end(), "\n";
	exit;
}
$region = $slice_src->subseq($start_pos, $end_pos);	printTime("get region");	# GRCh38

## check if source region is not full undefined
$undefPatt = ('N' x ($end_pos - $start_pos + 1)).$undefPatt;	# pattern length of region filled with 'N'
if($region eq $undefPatt) {
	print "Source region is completely undefined";
	exit;
}

$slice_targ = getSlice(!$src_targ);	# target release from db

# first try to search given region in target subseq with boundaries
# expanded by difference between chrom length from different assamblies
$diff = abs($slice_src->end() - $slice_targ->end());		# chrom length difference between different assamblies
# expand and check 'end' position
if(($last_pos = $end_pos + $diff) > $slice_targ->end()) { $last_pos = $slice_targ->end(); }

$seq_targ = $slice_targ->subseq($start_pos - $diff, $last_pos);		printTime("get seq");

if(printCoord($seq_targ, $diff)) { 		# try to search given region within target subseq
	$seq_targ = $slice_targ->seq();		printTime("get seq");
	if(printCoord($seq_targ, 0)) {		# try to search given region in target seq
		print "Source region was not found within target sequence\n";
	}
}
