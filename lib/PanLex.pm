package PanLex;
use strict;
use base 'Exporter';
use JSON;
use HTTP::Request;
use LWP::UserAgent;

use vars qw/@EXPORT/;
@EXPORT = qw/panlex_query panlex_query_all/;

my $API_URL = "http://if4.panlex.org/api";

# Send a query to the PanLex API at $url, with request body in $body.
# $body will automatically be converted to JSON, and the JSON response
# will be parsed and returned.
# If the request fails, the response will be undef.
sub panlex_query {
    my ($url, $body) = @_;
    
    $url = $url =~ m{^/} ? $API_URL . $url : $url;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/json');
    $req->content(encode_json($body || {}));
    
    my $ua = LWP::UserAgent->new;
    my $res = $ua->request($req);
    
    return undef unless $res && $res->code == 200;
    my $content = $res->content;
    eval { $content = decode_json($content) };
    return $@ ? undef : $content;
}

# Recursively query the PanLex API until all results are returned.
# Arguments are the same as for panlex_query.
# The result array of the returned value will contain all results,
# and resultNum will reflect the total number of results.
sub panlex_query_all {
    my ($url, $body) = @_;
    
    delete $body->{limit};
    $body->{offset} = 0;
    
    my $result;
    while (1) {
        my $this_result = panlex_query($url, $body);
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