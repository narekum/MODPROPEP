#! /usr/bin/perl
($inputquery, $userdir ) = @ARGV ;

#$userdir = "USER/USER-1";

system ("./blastall -p blastp -i ../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/$inputquery -o ../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/blastout.txt -d kinase_cat_dom.seq -b 1 -F SEG");

open OUT, ">../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/changed_res.out" ;
open OUTALIGNMENT, ">../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/alignment.html" ;
print OUTALIGNMENT "<html>\n<body bgcolor = '#FFFFFF'  TEXT = '#000099'>\n<pre>\n";



open OPENBLAST, "../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/blastout.txt" ;
chomp (@allblastlines = <OPENBLAST>);
print "$_\n" foreach @allblastlines ;

foreach (@allblastlines)
{
  $score++ if $_ =~ /^ Score/ ;
  $i = 1 if $_ =~ /^>/ ;
  $bestmatch = $_ if $_ =~ /^>/ ;
  $i = 0 if $_ =~ /^ Score/ and $i == 1 and $score == 2 ;
  $i = 0 if $_ =~ /^  Database:/ ;
  push @blastalignment, $_ if $i == 1 ;
}
undef $i ;
@for_id = split (/\s+/,$bestmatch);
$id = $for_id[2];
print " id  $id\n";
print OUT "Bestmatch:  $bestmatch\n";
print OUTALIGNMENT "<font color = 'red'>BLAST ALIGNMENT OF QUERY SEQUENCE WITH SEQUENCE OF PDB ID <font color='indigo'><b>\"$id\"</b></font></font>\n";
print OUTALIGNMENT "\n\n\n\n";
print OUTALIGNMENT "Bestmatch:  $bestmatch\n";
print OUT "$_\n" foreach @blastalignment ;
print OUTALIGNMENT "$_\n" foreach @blastalignment ;
print OUTALIGNMENT "</pre>\n</body>\n</html>\n";


foreach (@blastalignment)
{
        @splitline = split(/\s+/,$_);
  if ($_ =~ /^Query:/ and $i != 1 )
    {
        $_ =~ /.*?:\s+\d+\s+(.*)/;
        $alignindex = $-[1];
#     $first_res_no_query = substr ($_,7,2);
#     $i = 1 ;
#       @splitline = split(/\s+/,$_);
        $first_res_no_query = $splitline[1];
        $i = 1 ;
    }

  if ($_ =~ /^Sbjct:/ and $j != 1 )
    {
#yy     @splitline = split(/\s+/,$_);
        $first_res_no_subject = $splitline[1];
        $j = 1 ;
#     $first_res_no_subject = substr ($_,7,2);
#     $j = 1;
    }

  $query .= substr ($_,$alignindex,60 ) if $_ =~ /^Query:/;
  $subject .= substr ($_,$alignindex,60 ) if $_ =~ /^Sbjct:/;
  $align .= substr ($_,$alignindex,60 ) if $_ =~ /^           /;
}


print "my query $first_res_no_query   $query\n";
print "my align      $align\n";
print "my subject $first_res_no_subject $subject\n";

#$gaps_rem_sub = 
#$gap = "0" ;
#$tally = "1" ;
for ($i = 0; $i <= (length($query) - 1 );$i++  )
 { if ( substr($subject,$i,1) eq "-" )
      { substr($subject,$i,1) = "" ;
        substr($query,$i,1) = "" ;
        substr($align,$i,1) = "" ;
#       print substr($subject,$i - 1,1)," ",$first_res_no_subject + $i + 1,"  " if $tally == 1 ;
#        $tally = 0 ;
#         if ( substr($subject,$i + 1,1) ne "-"  )
#            { $gap++ ;
#              print "Gaps $gap   ",substr($subject,$i + 1,1),$first_res_no_subject + $i + 2,"  \n";
#              $gap = 0 ;
#              $tally = 1 ;
#            } 
        $i--;
#        $gap++ ;
        
      }
 }

print "my query $first_res_no_query   $query\n";
print "my align      $align\n";
print "my subject $first_res_no_subject $subject\n";


@align = split (//,$align) ;
@query = split (//,$query) ;
@subject = split (//,$subject) ;

$chainA = EXTSEQFROMCOORDFILE ("./TEMPLATES/$id.pdb","A" ); 

$lowercase_query = lc($query) ;
#print "$lowercase_query\n";
print OUT "\n     SUBJECT      |          QUERY       \n\n";
for ($k=0;$k<=$#align;$k++)
{ 
  if ($align[$k] =~ /[ |+]/)
   { 
     $change_letter = substr ($lowercase_query,$k,1);
     $change_letter =~ s/-/G/;
     $change_letter = uc ($change_letter);# print "$change_letter\n";
 
     $dash_query = returngaps ($query, $k );
     $dash_subject = returngaps ($subject, $k );
     print OUT $subject[$k],TAB( $subject[$k] )," ",$k + $first_res_no_subject - $dash_subject ,
           TAB ($k + $first_res_no_subject - $dash_subject)," |      ", 
           $query[$k],TAB( $query[$k] )," ",$k + $first_res_no_query - $dash_query,
           TAB ($k + $first_res_no_query - $dash_query),"\n" ;
     substr ($chainA,$k + $first_res_no_subject - $dash_subject - 1 ,1)  = $change_letter ;
   }
}

print "$lowercase_query\n";
$dash = returngaps ($query ) ;
print "dash  $dash \n";
#exit if $dash > 0 ;
#open TEMPLATE, "\/data\/narendra\/cgi-bin\/PROT_PEP_INTERACTION\/KINASES\/TEMPLATES\/$id.pdb";
$chainB = EXTSEQFROMCOORDFILE ("./TEMPLATES/$id.pdb","B" );
$chainC = EXTSEQFROMCOORDFILE ("./TEMPLATES/$id.pdb","C" );
#print " BC-----$chainC\n";
$seqtomodel = $chainA . $chainB . $chainC ;
print "$seqtomodel\n";
open SCWRLINPUTSEQ,">../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/temptomodel.seq" ;
print SCWRLINPUTSEQ "$seqtomodel\n";
system ("./scwrl3_lin/scwrl3 -i TEMPLATES/$id.pdb -s ../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/temptomodel.seq -o ../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/model.pdb > ../../../public_html/PROT_PEP_INTERACTION/KINASES/$userdir/scwrl_model.out");

sub returngaps 
{ my ($line,$index) = @_ ;
  my ($dash,$i,@array);
  
  $dash = 0 ; 
  @array = split (//,$line);
  for ($i;$i <= $#array ; $i++)
  {
    $dash++ if $array[$i] eq "-" ;
    return $dash if $i == ($index - 1) ;
  }
 
  return $dash ;
}

sub EXTSEQFROMCOORDFILE
{ my ($inputpdbfile,$chain) = @_ ;
  my (@coordinatelines,$res,$resno,$seq);

  %singleletter=qw(ALA A CYS C ASP D GLU E PHE F GLY G HIS H ILE I LYS K
                    LEU L MET M ASN N GLN Q ARG R SER S THR T VAL V TRP W
                    TYR Y PRO P);
  open (FILE,$inputpdbfile) or die "can not open $inputpdbfile :$!\n";
  while  ( chomp ($_= <FILE>)) {push @coordinatelines,$_ if $_ =~ /^ATOM/i and substr($_,21,1) =~ /$chain/i ;}
  for ($i=0;$i<= $#coordinatelines;$i++)
   { $res=substr($coordinatelines[$i],17,3);# print "$res\n";
     $resno=substr($coordinatelines[$i],23,4);# print "$resno\n";
   #  $chain=substr($coordinatelines[$i],21,1);
   #  $seq.= "*" if substr($coordinatelines[$i+1],21,1) ne $chain ;
     $seq.= $singleletter{$res} if substr($coordinatelines[$i+1],23,4) ne $resno ;
   }
  $seq = lc($seq);
  return $seq ;
}

sub TAB
{ my ($input)=@_;my $a;
  $a=length($input);
  if    ($a eq 1)       {return "       ";}
  elsif ($a eq 2)       {return "      ";}
  elsif ($a eq 3)       {return "     ";}
  elsif ($a eq 4)       {return "    ";}
  elsif ($a eq 5)       {return "   ";}
  elsif ($a eq 6)       {return "  ";}
  elsif ($a eq 7)       {return " ";}
  elsif ($a eq 8)       {return "";}
}

