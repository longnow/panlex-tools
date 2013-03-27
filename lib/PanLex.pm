package PanLex;
use strict;
use base 'Exporter';
use JSON;
use HTTP::Request;
use LWP::UserAgent;

use vars qw/@EXPORT/;
@EXPORT = qw/panlex_api_request panlex_api_request_all/;

my $API_URL = "http://if4.panlex.org/api";

sub panlex_api_request {
    my ($url, $body) = @_;
    
    my $req = HTTP::Request->new(POST => $API_URL . $url);
    $req->content_type('application/json');
    $req->content(encode_json($body || {}));
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    
    return undef unless $res && $res->code == 200;
    my $content = $res->content;
    eval { $content = decode_json($content) };
    return $@ ? undef : $content;
}

sub panlex_api_request_all {
    my ($url, $body) = @_;
    
    delete $body->{limit};
    $body->{offset} = 0;
    
    my $result;
    while (1) {
        my $this_result = panlex_api_request($url, $body);
        return undef unless $this_result;
        
        if ($result) {
            push @{$result->{result}}, @{$this_result->{result}};
            $result->{resultNum} += $this_result->{resultNum};
        } else {
           $result = $this_result; 
        }
        
        return $result if $this_result->{resultNum} < $this_result->{resultMax};
        $body->{offset} += $this_result->{resultNum};
    }
}