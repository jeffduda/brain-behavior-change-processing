#!/usr/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';

my $BIN = dirname(abs_path($0));

my $dir = "";
my $list = "";
my $odir = "ANTS";
my $study = "";
my $seqID = "";
my $template = "Kirby";
my $info;
my $slots = 2;


GetOptions( "subject-directory=s"     => \$dir,
            "subject-list=s"          => \$list,
            "output-directory-name=s" => \$odir,
            "study-id=s"              => \$study,
            "sequence-id=s"           => \$seqID,
            "template=s"              => \$template,
            "slots=i"                 => \$slots,
            "info-only"               => \$info )
or die( "Error in command line arguments\n");

# FIXME - Check that all inputs are accounted for


my @subs = ();
if ( -e "$list" ) {
  @subs = `cat $list`;
  chomp(@subs);
}
else {
  print("No subject list, scanning all subjects\n");
  my @subList = glob("${dir}/*");
  foreach my $sub ( @subList ) {
    push( @subs, basename($sub) );
    }
  }
#print( "@subs\n");

my $nSubs = scalar(@subs);
print( "Scanning $nSubs subjects for structural data\n");

foreach my $sub (@subs) {

  my @sessions = glob( "${dir}/${sub}/${study}*" );
  chomp(@sessions);
  foreach my $session (@sessions) {
  
    #my @sessionPath = split("/",$session);
    #my $sessionID = $sessionPath[scalar(@sessionPath-1)];
    my $sessionName = basename($session);
    
    my @sequences = glob( "${session}/Images/*${seqID}*" );
    chomp(@sequences);
    
    for my $sequence (@sequences ) {
            
      my @mprages = glob("${sequence}/NIFTIs/*_mprage.nii");
     
      if ( scalar(@mprages) < 1 ) {
        #print ("No MRPAGE found at ${sequence}/NIFTIs/*_mprage.nii \n");
        }
      elsif ( scalar(@mprages) > 1 ) {
        print( "Multiple MPRAGE images found at ${sequence}/NIFTIs/*.nii\n");
        }
      else {
        my $mprage = $mprages[0];
        my $outputDir = "${sequence}/Results/${odir}/";
        
        if ( ! -d "$outputDir" ) {
          `mkdir $outputDir`;
          }
          
        my $sequenceName = basename($sequence);
        my $outputName = "${outputDir}${sub}_${sessionName}_";


        my $exe = "$BIN/antsRunCorticalThickness.sh -i $mprage -o $outputName -t $template";

        if ( $info ) {
          print( "EXE = $exe\n");
        }
        else {
          print("Submitting qsub job for ${sub} ${sessionName} ${sequenceName}\n");
          my $qjob = "qsub -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=2 -V -binding linear:2 -pe unihost 2 -S /bin/sh -wd $outputDir $exe";
          #print( "$qjob\n");
          system($qjob);
          sleep 1 # helps prevent queue clog
          }            
        }
      }
    }
  }
