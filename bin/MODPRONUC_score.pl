#!/usr/bin/perl 
($nucfile,$nucfilerev,$proteinfile,$refatom,$file,$fastafile)=@ARGV;

use READMATRIX ;
use READPDB ;
use PPCALCS ;
use READFASTA;
%matrix=READMATRIX::READDNACONTACTMATRIX($file);

sub MATRIX_Sw_factor {
	my ($matrix)=@_;
	my %SwMatrix;  #Sw scores; 
	my %Swaa; # FpHINT (Best base for each animo acid)
	my @aa=qw ( A R N D C Q E G H I L K M F P S T W Y V );
	my @bases=qw( A C G T );
	foreach my $aa (@aa){
		foreach my $bb (@bases){
			$Swaa{$aa} = $$matrix{$aa}{$bb} if ( ! defined $Swaa{$aa} ) ;
			$Swaa{$aa} = $$matrix{$aa}{$bb}  if $Swaa{$aa} < $$matrix{$aa}{$bb} ;
			#print "$aa\t$bb\t$$matrix{$aa}{$bb}\n";
		}
	}
	foreach my $aa (@aa){
		#print "Swaa\t$aa\t", $Swaa{$aa} , "\n";
	}

	foreach my $aa (@aa){
                foreach my $bb (@bases){
                        $SwMatrix{$aa}{$bb}=$$matrix{$aa}{$bb} * 100 / $Swaa{$aa} ;
                }
        }
	return (%SwMatrix);
}

#%matrix=MATRIX_Sw_factor(\%matrix);

@aa=qw ( A R N D C Q E G H I L K M F P S T W Y V );
my @bases=qw( A C G T );
foreach my $aa (@aa){
	#print "$aa\t";
	foreach my $bb (@bases){
		#print $matrix{$aa}{$bb} , "\t";
	}
	#print "\n";
}

#exit;

#print $matrix{"A"}{"C"} , "\n";

#@coord=READPDB::GETPROTEINCOORDINATES($file," ","ca");
@nuccoords=READPDB::GETDNACOORDINATES($nucfile,"A","center", "");
@nuccoordsrev=READPDB::GETDNACOORDINATES($nucfilerev,"B","center", "");
@proteincoords=READPDB::GETPROTEINCOORDINATES($proteinfile," ","CB","T");


#%aa=READPDB::PDBRESIDUES("bb");

#print "$_\n" foreach @nuccoordsrev;
#print "$_\n" foreach @proteincoords;
#exit;

#print "$_\t",$aa{$_},"\n" foreach keys %aa;

#print "$_\n" foreach READPDB::RESNUMBERS(@nuccoords);

my($contacts,$list)=&READPDB::GETCONTACTS(\@nuccoords,\@proteincoords,8);
my($contactsrev,$listrev)=&READPDB::GETCONTACTS(\@nuccoordsrev,\@proteincoords,8);

#print "nucseq", shift @$contacts, "\n";
#exit;
foreach $a (@$contacts) {
	print "N->";
	print "$_|" foreach @$a ;
	print "$_\n";
}

print "reverse\n";
foreach $a (@$contactsrev) {
        print "N->";
        print "$_|" foreach @$a ;
        print "$_\n";
}


#print "$_\n" foreach @$list ;
#exit;

#($nucseq,$score)=PPCALCS::CALCSCORE($contacts,\%matrix);
#print "$nucseq\t$score\n";

$fastanucleotides=READFASTA::READSEQUENCES($fastafile,12);
print scalar keys %$fastanucleotides , " nucleotides\n";
#exit;
#print "$_\t",$$fastanucleotides{$_},"\n"  foreach keys %$fastanucleotides ;
foreach ( keys %$fastanucleotides ) {
	$$contacts[0] = $_ ;
	($nucseq,$score)=PPCALCS::CALCSCORE($contacts,\%matrix);
	$$contactsrev[0] = READFASTA::REVCOM($_);
	($nucseqrev,$scorerev)=PPCALCS::CALCSCORE($contactsrev,\%matrix);
	$dnabothstrandscore=$score+$scorerev ;	
	$tilt=abs($score-$scorerev)+1;
	$index=$dnabothstrandscore/$tilt;
	#print "$$fastanucleotides{$_}\t$nucseq\t$score\t$nucseqrev\t$scorerev\t$dnabothstrandscore\t$tilt\t$index\n";
	print "$nucseq\t$score\t$nucseqrev\t$scorerev\t$dnabothstrandscore\t$tilt\t$index\n";
}
