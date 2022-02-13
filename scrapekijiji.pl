#!/usr/bin/env perl
use strict;
use utf8;
binmode STDOUT, ":encoding(UTF-8)";
use URI;
use Web::Scraper;
use Data::Dumper;
use JSON::XS;
use File::Slurper qw(read_text read_binary write_binary);
sub URI::TO_JSON {
   my ($uri) = @_;
   $uri->as_string
}

sub json_write($$){
    my ($file, $data)=@_;
    write_binary($file, JSON::XS->new->utf8->pretty(1)->encode($data));
}

sub json_read($){
    my $file=shift;
    return {} if (! -f $file);
    my $json = read_binary($file);
    return {} if ($json eq "");
    return decode_json($json);
}

sub trim {
    s/^\s+//;
    s/\s+$//;
}

my $kijiji=scraper {
    process 'div[data-listing-id]', 'items[]' => scraper {
        process_first '[class]', class => [ '@class', \&trim, sub { s/\s+/ /g; } ];
        process_first '[data-listing-id]', id => [ '@data-listing-id' ];
        process_first '[data-vip-url]', url => [ '@data-vip-url', sub { $_="http://www.kijiji.ca".$_ unless /^(http:|https:)/i; return $_; } ];
        process_first '//div[@class="location"]/span[@class=""]', location => [ "TEXT", \&trim ];
        process_first 'span.date-posted', date => [ "TEXT", \&trim ];
        process_first '//img[@data-src]', image => [ '@data-src' ];
        process_first '//div[@class="description"]/text()', description => [ "TEXT", \&trim ];
        process_first '//div[@class="price"]/text()', price => [ "TEXT", \&trim ];
        process_first '//div[@class="price"]/text()', price_num => [ "TEXT", sub { s/[^\d.]+//g; } ];
        process_first 'div.msrp-price', price_msrp => [ "TEXT", qr/msrp:\s*(\S+)/i ];
        process_first 'div.financing-price', price_financing => [ "TEXT", \&trim ];
        foreach my $i (qw(title distance tagline details)){
            process_first "div.$i", "$i" => [ "TEXT", \&trim ];
        }
    };
    result 'items';
};

sub show_help(){
    print <<EOM;
Usage: $0 [options] file|URL

OPTIONS:
    --fields NAMES   Comma-separated list of fields to output
EOM
    exit 1;
}

my $input;
my @fields=qw(class date description details distance id image location price price_financing price_msrp price_num tagline title url);
for (my $i=0; $i<@ARGV; $i++){
    if ($ARGV[$i] eq "--fields"){
        $i++;
        @fields=split(',', $ARGV[$i]);
    } else {
        $input=$ARGV[$i];
    }
}

show_help() unless (defined($input));



my $items = $kijiji->scrape( URI->new($input) );


foreach my $i (@$items){
    foreach my $k (@fields){
        $i->{$k}=~s/[\n\t]+/  /g;
        print $i->{$k}, "\t";
    }
    print "\n";
}
