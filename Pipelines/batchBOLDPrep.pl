#!/usr/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';

# File locations for bbcp repo
my @PATH = split( "/", abs_path($0) );
pop(@PATH); 
pop(@PATH);
my $BASE = join( "/", @PATH);
my $DATA = $BASE."/Data";
my $PIPELINES = dirname(abs_path($0));

my $dir = "";
my $list = "";
my $odir = "ANTS";
my $study = "";
my $seqID = "";
my $template = "Kirby";
my $info;
my $t1seqID = "MPRAGE";
my $todir = "ANTS";
my $slots = 1;

GetOptions( "subject-directory=s"     => \$dir,
            "subject-list=s"          => \$list,
            "output-directory-name=s" => \$odir,
            "sequence-id=s"           => \$seqID,
            "t1-sequence-id"          => \$t1seqID,
            "t1-output-directory"     => \$todir,
            "slots=i"                 => \$slots,
            "info-only"               => \$info )
or die( "Error in command line arguments\n");

# Get subject List
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
print( "Scanning $nSubs subjects for BOLD data\n");



foreach my $sub (@subs) {

  my @sessions = glob( "${dir}/${sub}/${study}*" );
  chomp(@sessions);
  
  foreach my $session (@sessions) {
    print( "$sub $session\n");
    my $sessionName = basename($session);
   
    my @t1s = glob( "${session}/Images/*${t1seqID}*/NIFTIs/*.nii" );
    my @bolds = glob( "${session}/Images/*_${seqID}_*/NIFTIs/*.nii" );
    
    if ( (scalar(@t1s) > 0) && (scalar(@bolds) > 0) ) {

      my $t1 = $t1s[scalar(@t1s)-1];
      chomp($t1);
    
      my ($t1name, $t1path, $t1ext) = fileparse( $t1 );
      my @t1parts = split("/", $t1path);
      my $t1outdir = join("/", @t1parts[0..(scalar(@t1parts)-2)]);
      $t1outdir = $t1outdir."/Results/${todir}/";
      
      my @brains = glob("${t1outdir}*BrainSegmentation0N4.nii.gz");
      my @masks = glob("${t1outdir}*BrainExtractionMask.nii.gz");
    
      my $brain = "";
      my $mask = "";
    
      if (scalar(@brains) > 0) {
        $t1 = $brains[0];
        chomp($t1);
        }
      if (scalar(@masks) > 0) {
        $mask = $masks[0];
        chomp($mask);
        }
    
      chomp(@bolds);
    
      foreach my $bold (@bolds) {

        my @extensions = (".nii", ".nii.gz" );
        my ($boldname, $boldpath, $boldext) = fileparse( $bold, @extensions );
        my @boldparts = split("/", $boldpath);
        my $outdir = join("/", @boldparts[0..(scalar(@boldparts)-2)]);
        $outdir = $outdir."/Results/${odir}/";
    
        my $outname = $boldname."_bold.nii.gz"; 
        my $outfile = "${outdir}/${outname}";
        

        #my $sequenceName = basename($bold, @extensions);
        print( "$boldname \n");
    
        if ( ! -d $outdir ) { 
          `mkdir -p $outdir`;
          #print( "Created $outdir\n");
          }
        else {
          #print("Using $outdir\n");
          }
      
        if ( ( -e "$bold") && ( -e "$t1") && (-e "$mask") ) {

          
          if ( ! -e "${outdir}/${boldname}_bold.nii.gz") {

            my $exe = "${PIPELINES}/runBOLDPrep.sh -i $bold -o $outfile -s $t1 -x $mask";
            
            
            if ( $info ) {
              print( "EXE = $exe\n");
              }
            else {
              print("Submitting qsub job for ${sub} ${sessionName} ${boldname}\n");
              my $qjob = "qsub -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${slots} -V -binding linear:${slots} -pe unihost ${slots} -S /bin/sh -wd $outdir $exe";
              #print( "$qjob\n");
              system($qjob);
              sleep 1 # helps prevent queue clog
              }     

            }
          }
        else {
          print( "Missing inputs for $bold\n");
          }
            
        }
      }
    else {
      print( "WARNING ----- No BOLD found for $sub \n" );
      }
    }
  }
