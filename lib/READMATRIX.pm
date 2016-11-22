#!/usr/bin/perl -w

package READMATRIX;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( READDNACONTACTMATRIX READPROTEINCONTACTMATRIX READAAFREQUENCIES READMATRIXTOTAL WRITEMATRIX);

sub READDNACONTACTMATRIX {
	my ($file)=@_;
	my %contactmatrix=();
	my @dnabases=("","A","C","G","T");
	open OPEN,$file or die "Can not open contact DNA-Ammino Acid contact matrix file \"$file\":$!\n";
	while (<OPEN>) {
		next if $_=~/^#|^\s+#/;
		next if $_=~/^$|^\s+^/;
		my @split=split(/\t/,$_);
		for ( 1 .. 4) {
			$contactmatrix{$split[0]}{$dnabases[$_]}=$split[$_];
		}
		
	}
	return (%contactmatrix);
}

sub READPROTEINCONTACTMATRIX {
        my ($file)=@_;
        my %contactmatrix=();
        my @aminoacids=("","C","F","L","W","V","I","M","H","Y","A","G","P","N","T","S","R","Q","D","K","E");
        open OPEN,$file or die "Can not open Ammino Acid - Amino Acid contact matrix file \"$file\":$!\n";
        while (<OPEN>) {
                next if $_=~/^#|^\s+#/;
                next if $_=~/^$|^\s+^/;
                my @split=split(/\t/,$_);
                for ( 1 .. 20) {
                        $contactmatrix{$split[0]}{$aminoacids[$_]}=$split[$_];
                }

        }
        return (%contactmatrix);
}

sub READAAFREQUENCIES {
        my ($file)=@_;
        my %aafreq;
        open OPEN,$file or die "Can not open contact DNA-Ammino Acid contact matrix file \"$file\":$!\n";
        while (<OPEN>) {
                next if $_=~/^#|^\s+#/;
                next if $_=~/^$|^\s+^/;
                my @split=split(/\t/,$_);
                $aafreq{$split[0]}=$split[6];

        }
        return (%aafreq);
}

sub READMATRIXTOTAL {
        my ($file)=@_;
        my $totalcontacts;
        open OPEN,$file or die "Can not open contact DNA-Ammino Acid contact matrix file \"$file\":$!\n";
        while (<OPEN>) {
                next if $_=~/^#|^\s+#/;
                next if $_=~/^$|^\s+^/;
                my @split=split(/\t/,$_);
                for ( 1 .. 4) {
                        $totalcontacts+=$split[$_];
                }

        }
        return ($totalcontacts);
}

sub WRITEMATRIX {
        my ($contactmatrix)=@_;
        my %contactmatrix=%$contactmatrix;
        my @dnabases=qw( A C G T);
        my @aminoacids=qw( A R N D C Q E G H I L K M F P S T W Y V );
	print "#\t", join ("\t",@dnabases),"\n";
	foreach my $aa (@aminoacids) {
		print "$aa\t";
		foreach my $bb (@dnabases) {
			print $contactmatrix{$aa}{$bb} , "\t";
		}
		print "\n";
	}
}

sub LOGODDRATIOS {
        my ($contactfreqfile)=@_;
	my %contactfreq=READDNACONTACTMATRIX($contactfreqfile);
	my %aafreq=READAAFREQUENCIES($contactfreqfile);
	my $totalcontacts=READMATRIX::READMATRIXTOTAL($contactfreqfile);
        my @dnabases=qw( A C G T);
        my @aminoacids=qw( A R N D C Q E G H I L K M F P S T W Y V );
        foreach my $aa (@aminoacids) {
                foreach my $bb (@dnabases) {
			$contactfreq{$aa}{$bb} = sprintf ("%.2f", log ( ( $contactfreq{$aa}{$bb} / $totalcontacts ) / ( $aafreq{$aa} * 0.25 ) ) );
                }
        }
	return (%contactfreq);
}

1;

