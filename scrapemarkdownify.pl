#!/usr/bin/env perl
use strict;
use utf8;
use 5.016;
binmode STDIN, ":encoding(UTF-8)";
binmode STDOUT, ":encoding(UTF-8)";
use open ':encoding(UTF-8)';

sub show_help(){
    print <<EOM;
Usage: $0 [options] column_name ...

OPTIONS:
    --urlify INDEX,...   Indices of what fields should become links, the next field will contain the actual URL (Comma-separated list).
    --images INDEX,...   Indices of what fields should become images (Comma-separated list).
    --image-height STR   Image height to use. Default is "50px".
EOM
    exit 1;
}

my @names;
my %urlify;
my %images;
my $image_height='50px';
for (my $i=0; $i<@ARGV; $i++){
    if ($ARGV[$i] eq "--urlify"){
        $i++;
        %urlify=map { $_ => undef } split(',', $ARGV[$i]);
    } elsif ($ARGV[$i] eq "--images"){
        $i++;
        %images=map { $_ => undef } split(',', $ARGV[$i]);
    } elsif ($ARGV[$i] eq "--image-height"){
        $i++;
        $image_height=$ARGV[$i];
    } else {
        push(@names, $ARGV[$i]);
    }
}

show_help() unless (@names>0);

print "| ", join(" | ", @names), " |\n";
print "|", " - |"x@names, "\n";

use Data::Dumper;

while (<STDIN>){
    chomp;
    my @item=split("\t", $_);
    print "|";
    for (my $i=0; $i<@item; $i++){
        my $s=$item[$i];
        $s=~s/([|\[\]\(\)])/\\$1/g;
        if (exists($images{$i})){
            # MultiMarkDown:
            #$s='![]('.$s.' height='.$image_height.')' if ($s ne "");
            # Pandoc:
            $s='![]('.$s.'){height='.$image_height.'}' if ($s ne "");
        }
        if (exists($urlify{$i})){
            $i++;
            my $u=$item[$i];
            $u=~s/([|\[\]\(\)])/\\$1/g;
            $s='['.$s.']('.$u.')' if ($s ne "");
        }
        print " ", $s, " |";
    }
    print "\n";
    #0     1    2           3       4        5  6     7        8     9               10         11        12      13    14
    #class date description details distance id image location price price_financing price_msrp price_num tagline title url
    #printf("| [%s](%s) | ", $item[13], $item[14]);
    #printf("%s | ", $item[7]);
    #printf("%s | ", $item[4]);
    #printf("%s | ", $item[8]);
    #printf("%s | ", $item[2]);
    #printf("%s |\n", $item[3]);
}
print "\n\n";
