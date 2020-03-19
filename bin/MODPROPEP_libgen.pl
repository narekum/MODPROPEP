#! /usr/bin/perl
##
# fill affiliations and description
##

BEGIN {
        use Cwd qw(realpath cwd);
        use File::Basename;
        our ($fn, $dir) = fileparse(realpath($0));
	$dir =~ s/\/bin\/$// ;
}

print '
           __  __  ____  _____  _____  _____   ____  _____  ______ _____
          |  \/  |/ __ \|  __ \|  __ \|  __ \ / __ \|  __ \|  ____|  __ \
          | \  / | |  | | |  | | |__) | |__) | |  | | |__) | |__  | |__) |
          | |\/| | |  | | |  | |  ___/|  _  /| |  | |  ___/|  __| |  ___/
          | |  | | |__| | |__| | |    | | \ \| |__| | |    | |____| |
          |_|  |_|\____/|_____/|_|    |_|  \_\\\\____/|_|    |______|_|
                                           _     _ _
                                          | |   (_) |__   __ _  ___ _ __
                                          | |   | | |_ \ / _` |/ _ \ |_ \
                                          | |___| | |_) | (_| |  __/ | | |
                                          |_____|_|_.__/ \__, |\___|_| |_|
                                                         |___/

';

$template_lib_loc = "$dir/template-libs";

use lib "$dir/lib" ;
use File::Path qw(make_path);
use LWP::Simple;
use Getopt::Long ;
use READPDB ;

my $cmd=$0." ".join(" ",@ARGV); ### command line copy
$time_tag=$start_time=time;
$info="F" ;

GetOptions ("h|help"=>\$help,                     # --help         : print this help
            "l|lib=s"=>\$library_name,            # --lib          : Library name. Will be created if not found installed.
            "t|temp=s"=>\$src_lib,                # --temp         : Templates location
            "i|info=s"=>\$info                    # --info         : Prints information about the installed libraries. If the argument is 
                                                  #                  library name then prints that libraries information.
                                                  #                  options: P Prints list of installed libraries 
                                                  #                           "library name" Print information about "library name" if installed
           )
or &PRINTHELP($fn);

################################################################################

if( ( $info eq "F"  ) &&  ( defined $help || !$library_name || !$src_lib )) {
        &PRINTHELP($fn);
        exit;
}


################################################################################
# If -info flag is set to "list" check for the installed libraries


if ( $info eq "F") {

	#"Do Nothing";
	print "** No Library info to be reported\n\n";

} elsif ( lc($info) eq "list" ) {

        print "#  Running $fn with the \"-info\" option to \"list\" \n\n" ;
        print "   $cmd\n\n";

        print "   Libraries are installed at the following locaion:\n";
        print "     $template_lib_loc\n\n";

        opendir my $dh, $template_lib_loc || die "   Can not open library location  $template_lib_loc: $!\n   Exiting!!!   \n   Bye..." ;

        my @libraries = grep ! /^\.+$/, readdir $dh ;

        if ( @libraries ) {
                my $i = 0 ;
                print "   Following is the list of installed libraries:\n";
                foreach (@libraries) {
                        $i++;
                        print "     Lib $i : $_\n";
                }
                print "\n   Exiting!!! Bye!\n\n";
                exit ;
        } else {
                print "   **NO LIBRARY IS INSTALLED**:\n\n";
                print "   Exiting!!! Bye!\n\n";
                exit;
        }
	

} else {

        print "#  Running $fn with the \"-info\" option set to \"$info\" \n\n" ;
        print "   $cmd\n\n";

        print "   Libraries are installed at the following location:\n";
        print "     $template_lib_loc\n\n";

        print "   Information about library **$info**\n\n";
        if (! -d "$template_lib_loc/$info" ) {
                print "   **$info** is NOT installed\n\n";
                print "   Try running \"$fn -i list\" to get a list of installed libraries\n\n";
                print "   Exiting!!! Bye!\n\n";
                exit;
        } else {
                my ($trf_chain_name,$trf_chain_to_index,$trf_templates)=&READ_TRF("$template_lib_loc/$info/templates/TRF.list") ;
                my %trf_templates = %$trf_templates ;
                print "   Template installed are following\n";
                foreach (sort keys %trf_templates){
                        print "     $_","\t" ,$trf_templates{$_}, "\n";
                }
                print "   Exiting!!! Bye!\n\n";
                exit;
        }

}


################################################################################

my @options=( "$cmd",
           "--lib            $library_name",
           "--temp           $src_lib",
);

print "** Running $fn with the following options:\n\n" ;
print "      $_\n" foreach @options ;
print "\n";

print "** Library name: $library_name\n\n";
print "** Libaray path: $dir/template-lib/$library_name\n\n";


###############################################################################
# Checking the library 
if ( -d "$template_lib_loc/$library_name") {
	print "   Template Library names \"$library_name\" already exists at the following location:\n" ;
	print "   $template_lib_loc/$library_name\n\n";
} else {
	print "** Installing template library \"$library_name\"\n\n" ;
	print "   Creating template library \"$library_name\" at the following location:\n";
	print "   $template_lib_loc/$library_name/ \n\n";
	print "   Creating directories-\n\n";
	print "   $template_lib_loc/$library_name/templates\n";
	make_path ("$template_lib_loc/$library_name/templates");

	print "   $template_lib_loc/$library_name/index\n";
	make_path ("$template_lib_loc/$library_name/index");
}

###############################################################################
# Reading the source template library

## Testing if the source library and source template file exists
$src_template_list = "templates.list";

print "** Testing if the source template library and source template list \"templates.list\" EXISTS?\n\n";
if ( -d $src_lib ) {
	print "   Source library: \"$src_lib\" exists! \n";
	if ( -e "$src_lib/$src_template_list" ) {
		print "   Source Template list file \"$src_template_list\" exists! \n";
		if ( -z "$src_lib/$src_template_list" ) {
			print "   Source Template list file \"$src_template_list\" is empty! \n";
			exit;
		}
	} else {
		print "   Source Template list file \"$src_template_list\" DOES NOT exist! \n";
                        print "   Exiting!!! Bye!\n\n";
			exit;
	}
} else {
	print "   Source library: \"$src_lib\" DOES NOT exists! \n";
        print "   Exiting!!! Bye!\n\n";
	exit;

}


###############################################################################
## Reading the source template file
open STF, "$src_lib/$src_template_list" || die "Cant open $src_lib/$src_template_list: $! \n";
chomp (@readtemplates = <STF>);
foreach (@readtemplates ) {
	if ( $_ =~ /\s*#/ ) {    # ignore comments 
		next;
	} elsif ( $_ =~ /^\s*?\@chain\s+(.)\s*?:(.*)/ ) {      #@chain C:Peptide
                                                               #@chain A:PROTEIN_KINASE
		$chain_names{$1} = $2 ; #print "---$2\n";      #@index=A
	} elsif ( $_ =~ /^\s*?\@index\s*?=\s*?(.)/ ) {
        	push @chain_to_index, $1 ; #print "----$1\n";
        } else {
		my @pdb_templates_chains = split (/[\s|\t]+/, $_ ); #   2PHK.pdb	FG     AC
                                                                    #   change F to A, and G to C
		$template_copy{ $pdb_templates_chains[0] } = $pdb_templates_chains[1];
		$template_paste{ $pdb_templates_chains[0] } = $pdb_templates_chains[2];
	}
}

#### By now we have two hashes %template_copy and %template_paste containing the templates as keys and chain IDs as values
#### %template_paste contains chain IDs that must be written after changing original IDs



###############################################################################
## Printing the template record file

print "\n** Writing the template record file\n";

if ( -e "$template_lib_loc/$library_name/templates/TRF.list" ) {
	print "   $template_lib_loc/$library_name/templates/TRF.list already exists! Opening it for appending\n";
	# display the contents and record it. the purpose of recording is to be 
	# able to skip the templates and index for the sequences that are already there 
	# in the library
	($trf_chain_name,$trf_chain_to_index,$trf_templates)=READ_TRF("$template_lib_loc/$library_name/templates/TRF.list") ;
        # $trf_chain_name     : keys=chain id, value=name of the chain
        # $trf_chain_to_index : list of chain ids to be indexed
        # $trf_templates      : keys=template ids, values=string from all the chains in the file e.g. ABC. This is important because these will be parsed
	open TRF, ">>$template_lib_loc/$library_name/templates/TRF.list" || die "Cant open $template_lib_loc/$library_name/templates/TRF.list for appending:$!\n";
		
} else {
	print "   Opening $template_lib_loc/$library_name/templates/TRF.list already exists! for writing\n";
	open TRF, ">$template_lib_loc/$library_name/templates/TRF.list" || die "Cant open $template_lib_loc/$library_name/templates/TRF.list for writing:$!\n";
	print TRF "\@chain $_:", $chain_names{$_} , "\n" foreach keys %chain_names ; 
	print TRF "\@index=$_", "\n" foreach @chain_to_index ; 
}


###############################################################################
## Write the source templates to library 

print "\n** Writing PDB templates and sequence index to the library\n\n";
%trf_templates = %$trf_templates ;
foreach my $pdb ( sort keys %template_copy  ) {
	print "\n   READING $pdb for each of the chains: $template_copy{$pdb} for copying to library after changing the chains to $template_paste{$pdb} \n";
	
	if ( exists $trf_templates{$pdb} ) {
		print "   Template $pdb is already present in the library. Skipping it!!!\n";
		next;
	}

	my ($renumbered_pdb,$sequences) = WRITEPDB_TO_LIB("$src_lib/$pdb", $template_copy{$pdb}, $template_paste{$pdb});
        # $renumbered_pdb (array): all the coordinates of all the chains (eg ABC) renumbered sequencially residue wise and atom wise
        # $sequences (hash): keys=chain_id, value=aa sequence
        ###### new thing to be added. The original chain names to be changed to ABC
	my @renumbered_pdb = @$renumbered_pdb ;	

	my %sequences = %$sequences ;

	print "   Creating $template_lib_loc/$library_name/templates/$pdb\n";

	print TRF $pdb , "\t" , $template_paste{$pdb} , "\n" ; # Write templates to template list file. "1JBP.pdb	ABC"

	open WRITEPDB, ">$template_lib_loc/$library_name/templates/$pdb" || die "   Can not open $template_lib_loc/$library_name/templates/$pdb for writing: $! \n";	
	print WRITEPDB "$_\n" foreach @renumbered_pdb ;
        close WRITEPDB;


	foreach $indexchain ( @chain_to_index ) {
		$indexfile = "$template_lib_loc/$library_name/index/" . $chain_names{$indexchain} . "_" . "$indexchain.fasta";
		if ( -e  $indexfile ) {
			print "   $indexfile already exists! The sequences will be appended to it\n";
			open INDEXFILE, ">>$indexfile" || die "   Can not open $indexfile for appending: $! \n";
		} else {
			print "   $indexfile DOES NOT exists! Creating it\n";
			open INDEXFILE, ">$indexfile" || die "   Can not open $indexfile for writing: $! \n";
		}
		my $header = ">". $chain_names{$indexchain} . ":" . $pdb . ":" . $indexchain ;
		my @fasta = seq_to_fasta( $header, $sequences{$indexchain} );
		#print INDEXFILE ">", $chain_names{$indexchain}, ":" , $pdb , ":" , $indexchain, "\n" ;
		print INDEXFILE "$_\n" foreach @fasta ;
		print INDEXFILE "\n" ;
                close INDEXFILE ;
	}
} 

close TRF ;

print "\n\n   <-- DONE -->\n\n";


################################################################################

sub READ_TRF {
	my ($file)=@_ ;
	my %chain_names=();
	my @chain_to_index=();
	my %TRF_templates=();
	open FI, $file || die "Can not open $file for reading:$!\n";
	print "   Displaying the templates in the installed library\n\n";
	while (<FI>){
		chomp;
        	if ( $_ =~ /\s*#/ ) {
                	next;
        	} elsif ( $_ =~ /^\s*?\@chain\s+(.)\s*?:(.*)/ ) {
                	$chain_names{$1} = $2 ;                     #@chain C:Peptide
        	} elsif ( $_ =~ /^\s*?\@index\s*?=\s*?(.)/ ) {
                	push @chain_to_index, $1 ;                  #@index=A
        	} else {
			$_ =~ /^(.*?)\s+(.*)/ ;                     #2PHK.pdb        AC
			$TRF_templates{$1} = $2 ;
        	}
		
	}
	print "   Indexed chains are following\n" ;
	print "     $_ : ", $chain_names{$_} foreach @chain_to_index ;
	print "\n\n";

	print "   Chain names are following\n";
	print "     Chain $_ :" , $chain_names{$_} , "\n" foreach keys %chain_names;
	print "   \n";
	close FI ;
	return (\%chain_names, \@chain_to_index, \%TRF_templates) ;
}


################################################################################

sub seq_to_fasta {
	my ($header, $seq) = @_ ;
	my $break = 80;
	my @fasta = ();
	push @fasta,$header;
	for (my $i=0;$i<=length($seq);$i+=$break ){
		push @fasta, substr ($seq,$i,$break) ;
	}
	return (@fasta);
}


###############################################################################

sub WRITEPDB_TO_LIB {

	my ($inp_template,$chains_to_parse,$chains_to_write) = @_ ;

	$chains_to_parse =~ s/\s*//g; # remove spaces if any
	$chains_to_write =~ s/\s*//g; # remove spaces if any

	if ( length($chains_to_parse) != length($chains_to_write)  ) {
		print "   There is a mismatch in chains to be written to template \"$inp_template\" in the library from the source file. Please check!!!\n\n";
		exit;
	}

	my @chains_parse = split ( "", $chains_to_parse ) ;
	my @chains_write = split ( "", $chains_to_write ) ;

	my %chain_conversion=();

	for (my $i=0;$i<length($chains_to_parse);$i++ ) {
		$chain_conversion{ $chains_parse[$i]} = $chains_write[$i] ;
	}

	#$chain_to_index =~ s/\s*//g; 
	#my @chains_index = s/\s*//g; 
	my @coords = () ;
	my @renumbered_atoms = ();
	my %sequences=();
	foreach my $chain ( @chains_parse ) {
		#push @coords, "TER" if @coords ;
		my @coord=READPDB::GETCHAIN( "$inp_template" , $chain );
		my @coord_renamed_chain = READPDB::RENAME_CHAIN(\@coord, $chain, $chain_conversion{$chain});
		my @renumbered_coord=READPDB::RENUMCHAIN(@coord_renamed_chain);
		$seq = READPDB::RESCHAIN(@coord); #print "$seq\n";
		$sequences{ $chain_conversion{$chain} } = $seq ;
		push @coords, @renumbered_coord , sprintf("%-78s", "TER") ;
	}
	#my $sequence = READPDB::RESCHAIN(@renumbered_coords);
	@renumbered_atoms = READPDB::RENUM_ATOMS (@coords) ;
	#print "$_\n" foreach @renumbered_atoms ;
	#print "$_\n" foreach @coords ;
	#print $sequences{"A"},"\n" ;
	return (\@renumbered_atoms, \%sequences) ;
}

#@coord_1=READPDB::GETCHAIN("/Volumes/Macintosh SSD/Users/naren/data/MODPROPEP/MODPROPEP-master/bin/test_template_lib/1APM.pdb","A");
#@coord=READPDB::RENAME_CHAIN(\@coord_1,"A", "X");
#print "$_\n" foreach @coord ;
#@renumbered_coords=READPDB::RENUMCHAIN(@coord);
#print "$_\n" foreach @renumbered_coords ;
#$chain = READPDB::RESCHAIN(@renumbered_coords);
#print "$chain\n";
#print "$_\n" foreach @coord ;



################################################################################

sub PRINTHELP {
        my ($fn)=@_;

        print <<DES;
Usage: $fn -l library_name -t direcory_of_templates

Options:
  -h, --help      Print this help
  -l, --lib       Name of the library to be created.
  -t, --temp      Name of the directory containing the templates. The templates
                    will be added to the library
  -i, --info      Prints library information. (Default P)
                  Options:
                  P		: Prints a list of libraries installed.
                  "library_name": Prints information of "library_name" if installed
Examples:
\$ perl $fn -info 

\$ perl $fn -l kinases -t /data/user/kinase_complexes

DES

exit;
}


