#!/usr/bin/perl -w

package READPDB;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(GETPROTEINCOORDINATES GETDNACOORDINATES GETCONTACTS GETPPCONTACTS);

sub PROCESSPDB {
	my ($nucpdb,$nucchain,$nucref,$proteinpdb,$proteinchain,$proteinref,$cutoff)=@_;
	my @proteincoords=();
	my @nuccoords=();
	my @nucresnumbers=();
	@nuccoords=GETDNACOORDINATES($nucpdb,$nucchain,$nucref);
	@proteincoords=GETPROTEINCOORDINATES($proteinpdb,$proteinchain,$proteinref);
	@nucresnumbers=RESNUMBERS(@nuccoords);
	return();
}

sub GETCONTACTS {
	my ( $nuccoords,$proteincoords,$cutoff)=@_;
	my @nuccoords=@$nuccoords;
	my @proteincoords=@$proteincoords;
	my @contacts=();
	my @contactpairs=();
	my $nucseq;
	my ( $nucnum, $nucatom,$nucres,$protatom,$protres,$protnum,$distance);
	my %nucresnumbers=RESNUMBERS(@nuccoords);
	my @nucresnumbers = sort {$a<=>$b} keys %nucresnumbers ;
	my %aa=PDBRESIDUES("aa"); # get amino acids conversion hash;
	my %bb=PDBRESIDUES("bb"); # get nuc  bases  conversion hash;
	foreach $nucnum ( @nucresnumbers  ) {
		my %protcontacts=();
		my @protcontactarray=();
		foreach  $nucatom ( @nuccoords ) {
			next if $nucatom=~/^TER/;
			next if substr($nucatom,23,3) ne $nucnum ;
			$nucres=substr($nucatom,17,3);
			foreach  $protatom ( @proteincoords ) {
				next if $protatom=~/^TER/;
				$protres=substr($protatom,17,3);
				$protnum=substr($protatom,23,3);
				$distance=DISTANCE($nucatom,$protatom);
				if ($distance < $cutoff ) {
					my $contactpair =  substr($nucatom,0,26) . "\t" . substr($protatom,0,26) . "\t" . $distance ;
					push @contactpairs,$contactpair;
					my $protresnum= $aa{$protres} . $protnum ;
					$protcontacts{ $protresnum }=1;
				}
			}
		}
		$nucseq .= $bb{$nucresnumbers{$nucnum}} ;
		@protcontactarray= keys %protcontacts ;
		push @contacts, \@protcontactarray ;
	}
	unshift @contacts, "$nucseq";
	return (\@contacts,\@contactpairs);
}

sub GETPPCONTACTS {
        my ( $pepcoords,$proteincoords,$cutoff)=@_;
        my @pepcoords=@$pepcoords;
        my @proteincoords=@$proteincoords;
        my @contacts=();
        my @contactpairs=();
        my $pepseq;
        my ( $pepnum, $pepatom,$pepres,$protatom,$protres,$protnum,$distance);
        my %pepresnumbers=RESNUMBERS(@pepcoords);
        my @pepresnumbers = sort {$a<=>$b} keys %pepresnumbers ;
        my %aa=PDBRESIDUES("aa"); # get amino acids conversion hash;
        foreach $pepnum ( @pepresnumbers  ) {
                my %protcontacts=();
                my @protcontactarray=();
                foreach  $pepatom ( @pepcoords ) {
                        next if $pepatom=~/^TER/;
                        next if substr($pepatom,23,3) ne $pepnum ;
                        $pepres=substr($pepatom,17,3);
                        foreach  $protatom ( @proteincoords ) {
                                next if $protatom=~/^TER/;
                                $protres=substr($protatom,17,3);
                                $protnum=substr($protatom,23,3);
                                $distance=DISTANCE($pepatom,$protatom);
                                if ($distance < $cutoff ) {
                                        my $contactpair =  substr($pepatom,0,26) . "\t" . substr($protatom,0,26) . "\t" . $distance ;
                                        push @contactpairs,$contactpair;
                                        my $protresnum= $aa{$protres} . $protnum ;
                                        $protcontacts{ $protresnum }=1;
                                }
                        }
                }
                $pepseq .= $aa{$pepresnumbers{$pepnum}} ;
                @protcontactarray= keys %protcontacts ;
                push @contacts, \@protcontactarray ;
        }
        unshift @contacts, "$pepseq";
        return (\@contacts,\@contactpairs);
}

sub GETPROTEINCOORDINATES {
	my ($file,$chain,$refatominput,$excludebb)= @_; # $chains could be combined e.g. "AB" for chains A and B; refatom could be "any" or "CB" 
	my @coordinates=();
	my @backbone=qw( N CA C O);
	open ATOMLINE, $file or die "## ERROR ## READPDB::GETCOORDINATES; can not open PDB file $file for reading:$!\n";
	chomp ( my @template_read = <ATOMLINE> ) ;
  CLINE : foreach my $line (@template_read) {
		next if $line =~ /^$|^\s+$|^TER/;
		my $refatom=$refatominput;
		if ( $excludebb eq "T" ) {
			#print "exclude bb\n";
		 ALINE:	foreach ( @backbone  ){
				#print "$_\n";
				if ( ($line =~ /^ATOM/) && (substr($line,17,3) eq "GLY") && ( substr($line,13,3) =~ /^ca/igm)  ) {
					next ALINE ;
				}
				my $atom=substr($line,13,3); $atom=~s/\s+//g;
				if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $_ eq $atom  )){
					#print "skip ",substr($line,23,3)," " , substr($line,21,1), " " , substr($line,13,3) , "\t'$_'\t'$atom'\n";
					next CLINE;
				}
			}
		}
		#print "$line\n";
		#print "skip ",substr($line,23,3)," " , substr($line,21,1), " " , substr($line,13,3) , "\t$refatom\n";
  		if ( (substr($line,17,3) eq "GLY") && ($refatom =~ /^cb/igm)) { 
			$refatom = "ca";
		}
  		if ( ($refatom eq "any") || ($refatom eq "") ) { 
			$refatom = "";
		}          #$atom = "" if $refatom eq "any" ;
  		if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /[$chain]/i ) && ( substr($line,13,3)=~ /^$refatom/i)){ 
			push(@coordinates,$line);
		}
	}
	push @coordinates,"TER";
	return @coordinates;
}

sub GETDNACOORDINATES {
	my ($file,$chain,$refatom,$excludebb)= @_ ; # $chain should be single letter, $refatom could be "any" or comma separated list of atoms.
	my @coordinates=();
	my @backbone=qw( P OP1 OP2 O5' C5' C4' O4' C3' O3' C2' C1' );
	open ATOMLINE, $file or die "## ERROR ## READPDB::GETCOORDINATES; can not open PDB file $file for reading:$!\n";
	chomp ( my @template_read = <ATOMLINE> ) ;
 CLINE:	foreach my $line (@template_read) {
		next if $line =~ /^$|^\s+$|^TER/;
		if ( $excludebb eq "T"  ){
			foreach ( @backbone  ){
                		my $atom=substr($line,13,3); $atom=~s/\s+//g;
                		if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $_ eq $atom  )){
                                        	#print "skip ",substr($line,23,3)," " , substr($line,21,1), " " , substr($line,13,3) , "\t'$_'\t'$atom'\n";
                                	        next CLINE;
                        	        }
                	}
		}
		if ( ($refatom eq "any") || ($refatom eq "") ) {
			$refatom = "";
			if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( substr($line,13,3)=~ /^$refatom/i)){
				push(@coordinates,$line);
			}
		} elsif ( $refatom eq "center" ) {
			my $atom=substr($line,13,3); $atom=~s/\s+//g;
			if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $atom eq "N9" ) && ( substr($line,17,3) eq " DG"  )  ) {
				push(@coordinates,$line); next CLINE;
			} elsif ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $atom eq "N1" ) && ( substr($line,17,3) eq " DT"  ) ) {
				push(@coordinates,$line); next CLINE;
			} elsif ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $atom eq "N1" ) && ( substr($line,17,3) eq " DC"  )) {
				push(@coordinates,$line); next CLINE;
			} elsif ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( $atom eq "N9" ) && ( substr($line,17,3) eq " DA"  )) {
				push(@coordinates,$line); next CLINE;
			} else {
				next CLINE;
			}
			
		} else {
			my @atomlist=split(/,/,$refatom);
			foreach $refatom  ( @atomlist ) {
				if ( ($line =~ /^ATOM/) && (substr($line,21,1)=~ /$chain/i ) && ( substr($line,13,3) eq $refatom )){
					push(@coordinates,$line);
				}
			}
		}
	}
	push @coordinates,"TER";
	return @coordinates;
}

sub PDBRESIDUES {
	my ($type)=@_;
	my %singleletterAA=qw ( ALA A CYS C CYX C ASP D GLU E PHE F GLY G HIS H ILE I LYS K
                                LEU L MET M ASN N GLN Q ARG R SER S THR T VAL V TRP W TYR Y
                                TYR Y PRO P
				CY4 C 
                                HD2 H
                                HIE H
				HID H
			   );
	my %singleletterBB=qw ( DG  G DA  A DC  C DT  T );
	if ( $type eq "aa"  ) {
		return (%singleletterAA) ;
	} elsif ( $type eq "bb" ) {
		return (%singleletterBB);
	} else {
		print "## ERROR ## READPDB::PDBRESIDUES; required input $type not valid\n";
	}

}

sub RESNUMBERS {
	my (@coords)=@_;
	my %resnumbers=();
	foreach (@coords) {
		next if $_=~/^TER/;
		my $resname=substr($_,17,3); $resname=~s/\s+//g;
		$resnumbers{substr($_,23,3)}=$resname;
	}
	#my @resnumbers = sort { $a<=>$b } keys %resnumbers ;
	return (%resnumbers);
}

sub DISTANCE {
	my ($atom1,$atom2)=@_;
	my ($x, $y, $z, $x1, $y1, $z1);
	$x = substr($atom1,30,8); 
	$y = substr($atom1,38,8);
	$z = substr($atom1,46,8);
	$x1 = substr($atom2,30,8);
	$y1 = substr($atom2,38,8);
	$z1 = substr($atom2,46,8);
	my $distance = sqrt((($x-$x1)**2)+(($y-$y1)**2)+(($z-$z1)**2));
	return sprintf ( "%.2f" , $distance ) ;
}

1;

