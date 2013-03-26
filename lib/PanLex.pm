package PanLex;
use strict;
use base 'Exporter';
use JSON;
use HTTP::Request;
use LWP::UserAgent;

use vars qw/@EXPORT/;
@EXPORT = qw/panlex_api/;

my $API_URL = "http://if4.panlex.org/api";

sub panlex_api {
    my ($url, $body) = @_;
    
    my $req = HTTP::Request->new(POST => $API_URL . $url);
    $req->content_type('application/json');
    $req->content(encode_json($body || {}));
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    
    my $content = $res->content;
    eval { $content = decode_json($content) };
    $content = undef if $@;
    
    return $content;
}