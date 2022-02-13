#!/usr/bin/env perl
use strict;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
use URI;
use Web::Scraper;
use Data::Dumper;
use JSON::XS;
use File::Slurper qw(read_text read_binary write_binary);

my $scrape=scraper {
   process 'div[itemtype="http://schema.org/Thing/Automobile"] * a[itemprop="description"]', 'items[]' => '@href';
   result 'items';
};

sub show_help(){
    print <<EOM;
Usage: $0 URL
EOM
    exit 1;
}

my $input;
for (my $i=0; $i<@ARGV; $i++){
    $input=$ARGV[$i];
}

show_help() unless (defined($input));


my @items;
my $urls = $scrape->scrape(URI->new($input));
foreach my $u (@$urls){
    my $response = $scrape->__ua->get($u);
    if ($response->is_success){
        if ($response->decoded_content=~/w\.vehicleDetail = (.+)/){
            my $json=$1;
            $json=~s/^\s+//;
            $json=~s/\s+$//;
            $json=~s/;$//;
            my $json=decode_json($json);
            $json->{item_url}=$u;
            push(@items, $json);
        }
    }
}

foreach my $i (@items){
    foreach my $k (qw(year make model color style dateAdded item_url item_url)){
        $i->{$k}=~s/[\n\t]+/  /g;
        print $i->{$k}, "\t";
    }
    print "\n";
}
