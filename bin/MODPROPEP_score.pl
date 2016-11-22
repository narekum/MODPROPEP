#! /usr/bin/perl

#############################################
##  Narendra Kumar, PhD                     #
##  Epigenetics Unit                        #
##  Institute of Cancer Sciences            #
##  University of Glasgow, UK               #
##  narekum@gmail.com                       #
##  Copywrite: Narendra Kumar               #
#############################################

###############################################################################
## This is a rewritten version of MODPROPEP program originally developed at   #
## National Institute of Immunology, Delhi, INDIA.                            #
##                                                                            #
## MODPROPEP: a program for knowledge-based modeling of protein-peptide       #
## complexes                                                                  #
## Narendra Kumar and Debasisa Mohanty                                        #
## http://nar.oxfordjournals.org/content/35/suppl_2/W549.long                 #
###############################################################################

BEGIN {
        use Cwd qw(realpath cwd);
        use File::Basename;
        our ($fn, $dir) = fileparse(realpath($0));
}

use lib "$dir/../lib" ;
#use strict ;
use LWP::Simple;
use Getopt::Long;
use READMATRIX ;
use READPDB ;
use PPCALCS ;
use READFASTA;

print '
           __  __  ____  _____  _____  _____   ____  _____  ______ _____
          |  \/  |/ __ \|  __ \|  __ \|  __ \ / __ \|  __ \|  ____|  __ \
          | \  / | |  | | |  | | |__) | |__) | |  | | |__) | |__  | |__) |
          | |\/| | |  | | |  | |  ___/|  _  /| |  | |  ___/|  __| |  ___/
          | |  | | |__| | |__| | |    | | \ \| |__| | |    | |____| |
          |_|  |_|\____/|_____/|_|    |_|  \_\\\\____/|_|    |______|_|
                                                   ___  ___ ___  _ __ ___
                                                  / __|/ __/ _ \| .__/ _ \
                                                  \__ \ (_| (_) | | |  __/
                                                  |___/\___\___/|_|  \___|

';

my $cmd=$0." ".join(" ",@ARGV); ### command line copy

my $distance=4.5;
my $atomtype="any";
my $excludebb="F";

$time_tag=$start_time=time;

GetOptions ('h|help'=>\$help,                     # --help         : print this help
            "p|pdb=s" => \$pdb,                   # --pdbfile      : pdb file containing coordinates of protein(receptor) and ligand(peptide) (required)
            "r|rchain=s" => \$receptorchain,      # --rchain       : Receptor chain letter in pdb coordinate file (required)
            "l|lchain=s" => \$ligandchain,        # --lchain       : Ligand chain letter in pdb coordinate file (required)
            "s|sequence=s" => \$fastafile,        # --sequence     : protein sequence to be scanned in fasta format (required)
            "o|outfile=s" => \$outfile,           # --outfile      : name of the output file (required) 
            "m|matrix=s" => \$matrixfile,         # --matrixfile   : Scoring matrix file properly formated (required)
            "d|distance=f" => \$distance,         # --distance     : Distance for considering two atoms to be in contact in angstroms ( default 4.5)
            "a|atomtype=s" => \$atomtype,         # --atomtype     : Which atom types should be considered for contact between receptor and ligand  (default any)
                                                  #                  Options any=any atoms between receptor and ligand
                                                  #                          cb =c-beta; only C-beta to C-beta distances between receptor and ligand will be considered
            "e|excludebb=s"=> \$excludebb         # --excludebb    : Exclude backbone (sugar-phosphate atoms in DNA; N,C,CA,O atoms in Peptide/proteins) (default F)
                                                  #                  Options T (true) or F (false)
           )
or &PRINTHELP($fn);

if(defined $help || !$pdb || !$receptorchain || !$ligandchain || !$matrixfile || !$fastafile || !$outfile) {
        &PRINTHELP($fn);
        exit;
}

###############################################################################

my @options=( "$cmd",
           "--pdb            $pdb",
           "--rcahin         $receptorchain",
           "--lchain         $ligandchain",
           "--sequence       $fastafile",
           "--outfile        $outfile",
           "--matrix         $matrixfile",
           "--distance       $distance",
           "--atomtype       $atomtype",
           "--excludebb      $excludebb"
);

print "** Running $fn with the following options\n\n" ;
print "      $_\n" foreach @options ;
print "\n";

###############################################################################
## READ RECEPTOR (PROTEIN) COORDINATES
## ITERATE OVER EACH PROTEIN CHAIN (SUPPLIED BY THE USER)
print "** Reading receptor coordinates\n";
my @proteincoords=();
foreach ( split //, $receptorchain){
	print "   Reading $_ chain coordinates from file $pdb\n";
	my @coodinates=READPDB::GETPROTEINCOORDINATES($pdb,$_,$atomtype,$excludebb);
	push @proteincoords,@coodinates;
}
print "\n";
#print "$_\n" foreach @proteincoords;


###############################################################################
## READ RECEPTOR (PROTEIN) COORDINATES
print "** Reading ligand coordinates\n";
print "   Reading $ligandchain chain coordinates from file $pdb\n";
my @peptidecoords=READPDB::GETPROTEINCOORDINATES($pdb,$ligandchain,$atomtype,$excludebb);
print "\n";
#print "$_\n" foreach @peptidecoords;


###############################################################################
## READ SCORING MATRIX FILE
print "** Reading scoring matrix $matrixfile\n";
my %matrix=READMATRIX::READPROTEINCONTACTMATRIX($matrixfile);
print "   scoring matrix read\n\n";

###############################################################################
## CALCULATE CONTACT LIST
print "** Calculating atoms in contact between receptor and ligand\n";
my ($contacts,$list)=&READPDB::GETPPCONTACTS(\@peptidecoords,\@proteincoords,$distance); 
print "   Contact list generated\n";


###############################################################################
## READ FASTA FILE FOR SCANNING
print "** Reading protein sequence from fasta file $fastafile\n";
my $fastapeptides=READFASTA::READSEQUENCESPROT($fastafile,length($$contacts[0]));
print "   Fasta file read... generated overlapping peptides fragments of length ",length($$contacts[0]),"\n\n";


###############################################################################
## CALCULATING BINDING SCORES OF THE PEPTIDES 
print "** Calculating binding score of the ligand based on the scoring matrix\n";
my @SCORES=();
foreach ( keys %$fastapeptides ) {
	$$contacts[0] = $_ ;
	my ($pepseq,$score)=PPCALCS::CALCSCORE($contacts,\%matrix);
	push @SCORES, "$pepseq\t$score";
	#print "$pepseq\t$score\n";
}
my @SORTEDSCORES=sort { (split /\t/,$a)[1] <=> (split /\t/,$b)[1]} @SCORES ;
print "   Scores calculated\n\n";
#print "$_\n" foreach @SORTEDSCORES ;


###############################################################################
## Writing outfile 
print "** Writing output file\n";
open WR,">$outfile.txt";
print WR '################################################################################
#           __  __  ____  _____  _____  _____   ____  _____  ______ _____      #
#          |  \/  |/ __ \|  __ \|  __ \|  __ \ / __ \|  __ \|  ____|  __ \     #
#          | \  / | |  | | |  | | |__) | |__) | |  | | |__) | |__  | |__) |    #
#          | |\/| | |  | | |  | |  ___/|  _  /| |  | |  ___/|  __| |  ___/     #
#          | |  | | |__| | |__| | |    | | \ \| |__| | |    | |____| |         #
#          |_|  |_|\____/|_____/|_|    |_|  \_\\\\____/|_|    |______|_|         #
#                                                   ___  ___ ___  _ __ ___     #
#                                                  / __|/ __/ _ \| .__/ _ \    #
#                                                  \__ \ (_| (_) | | |  __/    #
#                                                  |___/\___\___/|_|  \___|    #
################################################################################
';
print WR "#Program run with the following options\n";
print WR "#$_\n" foreach @options ;
print WR "\n\n";
print WR "Peptide\tScore\n";
print WR "$_\n" foreach @SORTEDSCORES;
print WR "\n#End of the output\n";

print "   $outfile.txt written\n\n";
print "** Program ending normaly\n";

################################################################################


sub PRINTHELP {
	my ($fn)=@_;

        print <<DES;
Usage: $fn < -p PDBFILE -r RECEPTORCHAIN -l LIGANDCHAIN -m SCORINGMATRIX > [Options]

Options:
  -h, --help       Print this help
  -p, --pdbfile    Pdb file containing coordinates of protein(receptor) and ligand(peptide) (required)
  -r, --rchain     Receptor chain letter in pdb coordinate file (required)
  -l, --lchain     Ligand chain letter in pdb coordinate file (required)
  -s, --sequence   protein sequence to be scanned in fasta format (required)
  -o, --outfile    name of the outputfile (required)
  -m, --matrixfile Scoring matrix file properly formated (required)
  -d, --distance   Distance for considering two atoms to be in contact in angstroms ( default 4.5)
  -a, --atomtype   Which atom types should be considered for contact between receptor and ligand  (default any)
                   Options: 
                   any=any atoms between receptor and ligand
                   cb =c-beta; only C-beta to C-beta distances between receptor and ligand will be considered
  -e, --excludebb  Exclude backbone (sugar-phosphate atoms in DNA; N,C,CA,O atoms in Peptide/proteins) (default F)
                   Options: T (true), F (false)

Examples:
\$ perl $fn --pdbfile complex.pdb -rchain A -lchain L -matrixfile MJ.mat -distance 6 -atomtype CB
\\or\\
\$ perl $fn --p complex.pdb -r A -l L -m MJ.mat -d 6 -a CB 

DES
exit;
}
