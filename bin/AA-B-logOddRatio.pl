#!/usr/bin/perl 

BEGIN {
        use Cwd qw(realpath cwd);
        use File::Basename;
        our ($fn, $dir) = fileparse(realpath($0));
}

use lib "$dir/../lib" ;

($contactfreqfile)=@ARGV;

use READMATRIX ;

%contactfreq=READMATRIX::READDNACONTACTMATRIX($contactfreqfile);
%aafreq=READMATRIX::READAAFREQUENCIES($contactfreqfile);
$total=READMATRIX::READMATRIXTOTAL($contactfreqfile);
print "$_\t",$aafreq{$_} foreach keys %aafreq;
print "Total=$total\n";

&READMATRIX::WRITEMATRIX(\%contactfreq);

%logoddmat=READMATRIX::LOGODDRATIOS($contactfreqfile);
&READMATRIX::WRITEMATRIX(\%logoddmat);
