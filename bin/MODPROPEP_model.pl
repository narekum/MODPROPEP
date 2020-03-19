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
use READPDB ;
use READFASTA;

print '
           __  __  ____  _____  _____  _____   ____  _____  ______ _____
          |  \/  |/ __ \|  __ \|  __ \|  __ \ / __ \|  __ \|  ____|  __ \
          | \  / | |  | | |  | | |__) | |__) | |  | | |__) | |__  | |__) |
          | |\/| | |  | | |  | |  ___/|  _  /| |  | |  ___/|  __| |  ___/
          | |  | | |__| | |__| | |    | | \ \| |__| | |    | |____| |
          |_|  |_|\____/|_____/|_|    |_|  \_\\\\____/|_|    |______|_|
                                                                 _      _
                                             _ __ ___   ___   __| | ___| |
                                            | :_ : _ \ / _ \ / _` |/ _ \ |
                                            | | | | | | (_) | (_| |  __/ |
                                            |_| |_| |_|\___/ \__,_|\___|_|

';

my $chain = "All" ;
my $cmd=$0." ".join(" ",@ARGV); ### command line copy

$time_tag=$start_time=time;

$scwrl_dir = "/Users/naren/data/gc_nkniii/static/projects/modpropep/external_prog/scwrl" ;

GetOptions ('h|help'=>\$help,                     # --help         : print this help
            "p|pdb=s" => \$pdb,                   # --pdbfile      : pdb file containing coordinates of chains to be mutated (required)
            "c|chain=s" => \$chain,               # --chain        : Chains (letters) in pdb coordinate file to keep (Default: all chains)
            "m|mutate=s" => \$mutate,             # --mutate       : Chain (letter) to be mutated in pdb coordinate file (required)
            "s|sequence=s" => \$fastafile,        # --sequence     : protein sequence with mutations to be modelled (required)
            "o|outfile=s" => \$outfile,           # --outfile      : name of the output file (required) 
           )
or &PRINTHELP($fn);

if(defined $help || !$pdb || !$mutate || !$fastafile || !$outfile) {
        &PRINTHELP($fn);
        exit;
}

###############################################################################

my @options=( "$cmd",
           "--pdb            $pdb",
           "--chain          $chain",
           "--mutate         $mutate",
           "--sequence       $fastafile",
           "--outfile        $outfile",
);

print "**Running $fn with the following options**\n\n" ;
print "      $_\n" foreach @options ;
print "\n";


###############################################################################
# GETTING CHAINS FROM PDB FILE
my @ids = READPDB::GETCHAIN_IDS ($pdb);


###############################################################################
# GETTING COORDINATES and AA SEQUENCES of the CHAINS
foreach my $chain (@ids) {
	print "$chain\n";
}



###############################################################################
# HELP SUBROUTINE
sub PRINTHELP {
        my ($fn)=@_;

        print <<DES;
Usage: $fn < -p PDBFILE -m CHAIN_TO_MUTATE -s SEQUENCE_TO_MODEL -o OUTFILE > [ -c PDBCHAINS_TO_KEEP ]

Options:
  -h, --help       Print this help.
  -p, --pdb        Input Pdb file.
  -c, --chains     Chains (letters) in pdb file to keep. (Default: all chains)
  -m, --mutate     Chain (letter) to be mutated in pdb file. (Required)
  -s, --sequence   Protein sequence (containing mutations) to be modelled. (Required)
  -o, --outfile    Name of the output PDB file. (Required)

Examples:
\$ perl $fn --pdb kinase.pdb --chains ABC --mutate C --sequence peptide.fasta --outfile kinase_mutated.pdb 
\\or\\
\$ perl $fn -p kinase.pdb -c ABC -m C -s peptide.fasta -o kinase_mutated.pdb

DES
exit;
}
