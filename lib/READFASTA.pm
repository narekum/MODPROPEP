#!/usr/bin/perl -w

package READFASTA;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( REVCOM READSEQUENCES READSEQUENCESPROT);

sub READSEQUENCES {
	my ($fasta,$nuclength)=@_;
	my %nucleotideHash;
	my $sequence="";
	open OPEN,$fasta or die ("## ERROR ## READSEQUENCES::READFASTA; Can not read the sequence file $fasta :$!\n");
	while (<OPEN>){
		chomp;
		if ( $_=~/^>/ ) {
			next if ( (length $sequence) < $nuclength ) ;
			#print "$sequence\n";
			my $currentNucGroup=SEPARATE($sequence,$nuclength);
			foreach ( @$currentNucGroup ){
				$nucleotideHash{$_}++;
			}
			$sequence="";
			next;
		}
		$sequence .= $_ ;
		
		
	}
	my $currentNucGroup=SEPARATE($sequence,$nuclength);
	foreach ( @$currentNucGroup ){
		$nucleotideHash{$_}++;
	}
	return (\%nucleotideHash);

}

sub READSEQUENCESPROT {
        my ($fasta,$nuclength)=@_;
        my %nucleotideHash;
        my $sequence="";
        open OPEN,$fasta or die ("## ERROR ## READSEQUENCES::READFASTA; Can not read the sequence file $fasta :$!\n");
        while (<OPEN>){
                chomp;
                if ( $_=~/^>/ ) {
                        next if ( (length $sequence) < $nuclength ) ;
                        #print "$sequence\n";
                        my $currentNucGroup=SEPARATEPEP($sequence,$nuclength);
                        foreach ( @$currentNucGroup ){
                                $nucleotideHash{$_}++;
                        }
                        $sequence="";
                        next;
                }
                $sequence .= $_ ;


        }
        my $currentNucGroup=SEPARATEPEP($sequence,$nuclength);
        foreach ( @$currentNucGroup ){
                $nucleotideHash{$_}++;
        }
        return (\%nucleotideHash);

}

sub SEPARATEPEP {
        my ($seq,$length)=@_;
        my $total_length=length($seq);
        my @nucleotides;
        foreach (my $i=0;$i<=$total_length-$length;$i++){
                my $frag=substr($seq,$i,$length);
                push @nucleotides,$frag;
        }
        return (\@nucleotides);
}

sub SEPARATE {
        my ($seq,$length)=@_;
        my $total_length=length($seq);
	my @nucleotides;
        foreach (my $i=0;$i<=$total_length-$length;$i++){
                my $frag=substr($seq,$i,$length);
                push @nucleotides,$frag;
                push @nucleotides,REVCOM($frag);
        }
	return (\@nucleotides);
}

sub REVCOM {
        my($strand)=@_;
        my $revmotif=reverse $strand;
        $revmotif =~ tr/ACGT/TGCA/ ;
        return ($revmotif);
}
