#!/usr/bin/env perl
use strict;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
use URI;
use Web::Scraper;
use Data::Dumper;
use File::Slurper qw(read_text read_binary write_binary);

sub trim {
    s/^\s+//;
    s/\s+$//;
}

my $scrape=scraper {
   process 'table#table-example > tbody > tr', 'items[]' => scraper {
       process_first "td:nth-child(1)", "year" => [ "TEXT", \&trim ];
       process_first "td:nth-child(2)", "make" => [ "TEXT", \&trim ];
       process_first "td:nth-child(3)", "model" => [ "TEXT", \&trim ];
       process_first "td:nth-child(4)", "color" => [ "TEXT", \&trim ];
       process_first "td:nth-child(5)", "style" => [ "TEXT", \&trim ];
       process_first "td:nth-child(6)", "date" => [ "TEXT", \&trim ];
   };
   result 'items';
};

sub show_help(){
    print <<EOM;
Usage: $0 location_id
EOM
    exit 1;
}

my $location_id;
for (my $i=0; $i<@ARGV; $i++){
    $location_id=$ARGV[$i];
}

show_help() unless (defined($location_id));



$scrape->__ua->default_header( 'Cookie' => 'loc='.$location_id );
my $items = $scrape->scrape(URI->new('https://www.bucksautoparts.com/bucks/check_inventory.jsp'));

foreach my $i (@$items){
    foreach my $k (qw(year make model color style date)){
        $i->{$k}=~s/[\n\t]+/  /g;
        print $i->{$k}, "\t";
    }
    print "\n";
}
