#!/usr/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';


sub PrintUsage{
print <<USAGE

antsBatchCorticalThickness.pl
  This program processes the T1 images for a set of subjects in order to provide
  1) Brain extraction (i.e. skull-stripping)
  2) A six-compartment segmentation( CSF,GM,WM,Deep Gray, Brain stem and cerebellum)
  3) Registration to template
  4) Estimation of cortical thickness
  
Required Inputs
  --subject-directory - location of subject directories (full path, not relative)
  --sequence-id - string indicating identifier of T1 data, example="MPRAGE"
  
Optional Inputs
  --subject-list - a text file containing IDs of subjects to process. Default is to process all subjects in the directory
  --template - name of template defined in Data/templates.xml file. Default="Kirby"
  --slots - number of slots for qsub. Default=2
  --template-xml - custom template file
  --info-only - print commands to be run, but don't actually run or submit them
  --help - print this usage
  
USAGE
;

}
my $AHEAD = "/data/jag/bbcp/pkg/ahead_joint/turnkey/bin/hippo_seg_WholeBrain_itkv4_v3.sh";

# Check for ANTSPATH
my $ANTSPATH = $ENV{'ANTSPATH'};
my $ACT = $ANTSPATH."/antsCorticalThickness.sh";
if ( ! -e "$ACT" ) {
  print( "Can not find antsCorticalThickness scripts.\n" );
  print( "ANTSPATH = $ANTSPATH\n"); 
  exit 1;
  }


# File locations for bbcp repo
my @PATH = split( "/", abs_path($0) );
pop(@PATH); 
pop(@PATH);
my $BASE = join( "/", @PATH);
my $DATA = $BASE."/Data";
my $PIPELINES = dirname(abs_path($0));


# default option values
my $dir = "";
my $list = "";
my $odir = "AHEAD";
my $study = "";
my $seqID = "";
my $template = "3T";
my $info;
my $help;
my $slots = 2;
my $templateDir = "";

my $argc = scalar(@ARGV);

GetOptions( "input-directory=s"       => \$dir,
            "subject-list=s"          => \$list,
            "output-directory-name=s" => \$odir,
            "study-id=s"              => \$study,
            "sequence-id=s"           => \$seqID,
            "template=s"              => \$template,
            "slots=i"                 => \$slots,
            "help"                    => \$help,
            "info-only"               => \$info )
or die( "Error in command line arguments\n");

if ( $help || ($argc ==0)) {
  PrintUsage();
  exit 0;
  }

# Get template info
if ( $template == "3T" ) {
  $templateDir = "/home/wujue/ahead_joint/turnkey/data/3T/";
  }
elsif ( $template == "1.5T" ) {
  $templateDir = "/home/wujue/ahead_joint/turnkey/data/1_5T";
}
elsif ( $template == "ADNI3T" ) {
  $templateDir = "/home/wujue/ahead_joint/turnkey/data/ADNI3T";
  }
elsif ( $template == "ADNI1.5T" ) {
  $templateDir = "/home/wujue/ahead_joint/turnkey/data/ADNI1_5T";
  }
elsif ( $template == "WholeBrain") {
  $templateDir = "/home/wujue/ahead_joint/turnkey/data/WholeBrain";
  }
else {
  $templateDir = $template;
  }

# Get subject list
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
my $nSubs = scalar(@subs);
if ( $nSubs > 0 ) {
  print( "Scanning $nSubs subjects for structural data\n");
  }
else {
  print( "No subjects found in $dir\n");
  exit 1;
  }


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
            
      my @mprages = glob("${sequence}/NIFTIs/*.nii");
     
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
        my $outputName = "${outputDir}${sessionName}_ahead_hippocampus.nii.gz";
        
        my $aheadCommand = "${PIPELINES}/runAhead.sh -i $mprage -d $outputDir -o $outputName -t $templateDir -e $AHEAD ";      

        #my $exe = "$PIPELINES/antsRunCorticalThickness.sh -i $mprage -o $outputName -t $template";

        if ( $info ) {
          print( "EXE = $aheadCommand\n");
        }
        else {
          print("Submitting qsub job for ${sub} ${sessionName} ${sequenceName}\n");
          my $qjob = "qsub -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${slots} -V -binding linear:${slots} -pe unihost ${slots} -S /bin/sh -wd $outputDir $aheadCommand";
          #print( "$qjob\n");
          system($qjob);
          sleep 1 # helps prevent queue clog
          }            
        }
      }
    }
  }
