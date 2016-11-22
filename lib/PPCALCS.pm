#!/usr/bin/perl -w

package PPCALCS;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( CALCSCORE );

sub CALCSCORE {
	my($contacts,$matrix)=@_;
	my @contacts=@$contacts;
	my $nucseq=shift @contacts;
	my $score=0;
	#$nucseq="GGGGGGAGGGGG";
	#print "nucseq $nucseq \n";
	if ( length ( $nucseq ) != @contacts  ) {
		print "## ERROR ## PPCALCS::CALCSCORE Unequal length of nucleotide ($nucseq)and contact arrays\n";
		exit;
	}
	my @basearray= split //, $nucseq ;
	for my $i ( 0 .. $#basearray ) {      # iterate over each position in the nucleotide sequence
		my $base = $basearray[$i];
		#my @contactres=@{$contacts[$i]};
		foreach my $res (@{$contacts[$i]}) {
			$res=~s/\s+\d+//;
			$res=~s/\d+//;
			if ( exists $$matrix{$res}) {
				$score+=$$matrix{$res}{$basearray[$i]};
				#print "$res\t$basearray[$i]\t$$matrix{$res}{$basearray[$i]}\n";
			} else {
				print "'$res' not found. please check\n";
			}
			#print $basearray[$i] , "\t" , "$res\t" , $$matrix{$res}{$basearray[$i]} ,"\t$score", "\n"
		}
	}
	return ($nucseq,sprintf("%.1f",$score));
}
