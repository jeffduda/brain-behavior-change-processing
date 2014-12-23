#!/usr/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
#use Getopt::Long;

my $ANTSPATH = $ENV{ANTSPATH};

# args to remove - input, output, moco
my $antsApplyCall = "";
my $inputIdx = 0;
my $outputIdx = 0;
my $mocoIdx = 0;
my $count = 0;

foreach (@ARGV) {
  if ( index( $_, "-i") >= 0) {
    $inputIdx = $count;
  }

  if ( index( $_, "--input") >= 0) {
    $inputIdx = $count;
  }

  if ( index( $_, "-o") >= 0 ) {
    $outputIdx = $count;
  }

  if ( index( $_, "--output") >= 0) {
    $outputIdx = $count;
  }

  if ( index( $_, "-m") >= 0 ) {
    $mocoIdx = $count;
  }

  if ( index( $_, "--moco") >= 0) {
    $mocoIdx = $count;
  }

  $count = $count + 1;

}

my $inputFile = $ARGV[$inputIdx+1];
my $outputFile = $ARGV[$outputIdx+1];
my $mocoFile = $ARGV[$mocoIdx+1];

# check that all exist
my @removes = ($inputIdx, $inputIdx+1, $outputIdx, $outputIdx+1, $mocoIdx, $mocoIdx+1);

my $argString = "";
$count = 0;
foreach( @ARGV ) {
  if( ($count != $inputIdx) && ($count != ($inputIdx+1)) && ($count != $outputIdx) && ($count != ($outputIdx+1)) && ($count != $mocoIdx) && ($count != ($mocoIdx+1)) ) {
    $argString = $argString." ".$_;
  }
  $count = $count + 1;
}

print( "Passed params = $argString\n");

print( "Splitting up $inputFile\n");
my $odir = dirname( $outputFile );
my $tmpDir = $odir."/warpTmpDir/";
`mkdir $tmpDir`;

my $spacing = `ImageMath 4 x PH $inputFile | grep Spacing`;
my $timespacing = substr( $spacing, rindex($spacing, ",")+1 );
$timespacing = substr( $timespacing, 0, index($timespacing, "]"));

my $origin = `ImageMath 4 x PH $inputFile | grep Origin`;
my $timeorigin = substr( $origin, rindex($origin, ",")+1 );
$timeorigin = substr( $timeorigin, 0, index($timeorigin, "]"));

print( "Spacing: $timespacing\n");

`ImageMath 4 $tmpDir/timeseries.nii.gz TimeSeriesDisassemble $inputFile`;

my @timepoints = glob("${tmpDir}timeseries????.nii.gz");
chomp(@timepoints);

foreach  my $time (@timepoints) {
  # get moco transform
  my $exe = "${ANTSPATH}/antsApplyTransforms $argString -i $time -o $time -t MOCO";
  print( "$exe \n");

}

`ImageMath 4 $outputFile TimeSeriesAssemble $timespacing $timeorigin ${tmpDir}timeseries????.nii.gz`;




`rm -R $tmpDir`;
