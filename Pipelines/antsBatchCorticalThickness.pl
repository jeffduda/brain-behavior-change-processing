#!/usr/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';
use XML::Simple;
use Data::Dumper;

# Function definition
sub GetTemplate{
  # get total number of arguments passed.
  
  my %templateHash = ();
  
  my $templateXML = $_[0];
  my $templateName = $_[1];

  my $xml = new XML::Simple;
  my $xmlData = $xml->XMLin($templateXML);

  #print Dumper($xmlData);

  my $head = $xmlData->{template}->{$templateName}->{brain};
  if ( ! defined $head ) {
    print( "Template not found\n");
    exit 1;
    }
  $templateHash{'head'} = $head;

  my $brain = $xmlData->{template}->{$templateName}->{brain};
  if ( ! defined $head ) {
    print( "Template brain not found\n");
    exit 1;
    }
  $templateHash{'brain'} = $brain;

  my $priors = $xmlData->{template}->{$templateName}->{priors};
  if ( ! defined $head ) {
    print( "Template priors not found\n");
    exit 1;
    }
  $templateHash{'priors'} = $priors;

  my $emask = $xmlData->{template}->{$templateName}->{extractionmask};
  if ( ! defined $head ) {
    print( "Template extraction mask not found\n");
    exit 1;
    }
  $templateHash{'extractionmask'} = $emask;

  my $pmask = $xmlData->{template}->{$templateName}->{probmask};
  if ( ! defined $head ) {
    print( "Template probabilistic mask not found\n");
    exit 1;
    }
  $templateHash{'probmask'} = $pmask;

  return %templateHash;
}

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
my $odir = "ANTS";
my $study = "";
my $seqID = "";
my $template = "Kirby";
my $info;
my $slots = 2;
my $templateXML = $DATA."/templates.xml";
#$templateXML = $DATA."/test.xml";

GetOptions( "subject-directory=s"     => \$dir,
            "subject-list=s"          => \$list,
            "output-directory-name=s" => \$odir,
            "study-id=s"              => \$study,
            "sequence-id=s"           => \$seqID,
            "template=s"              => \$template,
            "slots=i"                 => \$slots,
            "template-xml=s"          => \$templateXML,
            "info-only"               => \$info )
or die( "Error in command line arguments\n");

# Get template info
my %templateHash = GetTemplate( $templateXML, $template );
#print Dumper(\%templateHash);


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
        my $outputName = "${outputDir}${sessionName}_";
        
        my $actCommand = "$ACT -d 3 -a $mprage -e $templateHash{'head'} -m $templateHash{'probmask'} -f $templateHash{'extractionmask'} -p $templateHash{'priors'} -t $templateHash{'brain'} -k 0 -n 3 -w 0.25 -o $outputName";      

        #my $exe = "$PIPELINES/antsRunCorticalThickness.sh -i $mprage -o $outputName -t $template";

        if ( $info ) {
          print( "EXE = $actCommand\n");
        }
        else {
          print("Submitting qsub job for ${sub} ${sessionName} ${sequenceName}\n");
          my $qjob = "qsub -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${slots} -V -binding linear:${slots} -pe unihost ${slots} -S /bin/sh -wd $outputDir $actCommand";
          #print( "$qjob\n");
          system($qjob);
          sleep 1 # helps prevent queue clog
          }            
        }
      }
    }
  }
