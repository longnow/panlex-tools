package PanLex::Client;
use strict;
use parent 'Exporter';
use JSON::MaybeXS;
use HTTP::Request;
use List::Util 'any';
use LWP::UserAgent;

our @EXPORT = qw(panlex_query panlex_query_all panlex_query_map panlex_norm);

$PanLex::Client::ARRAY_MAX = 10000;

my $API_URL = $ENV{PANLEX_API};

sub import {
    my $class = shift;
    $class->export_to_level(1, $class, @EXPORT);

    if (!defined $API_URL) {
        $API_URL = (any { $_ eq ':v1' } @_)
            ? 'https://api.panlex.org'
            : 'https://api.panlex.org/v2';
    }
        print $API_URL, "\n";

    if (any { $_ eq ':limit' } @_) {
        require Sub::Throttler;
        require Sub::Throttler::Rate::AnyEvent;

        Sub::Throttler::throttle_it_sync('panlex_query');
        Sub::Throttler::Rate::AnyEvent
            ->new(period => 60, limit => 120)
            ->apply_to_functions('panlex_query');
    }
}

# Send a query to the PanLex API at $url, with request body in $body.
# $body will automatically be converted to JSON, and the JSON response
# will be parsed and returned.
# If the request fails, the response will be undef.
sub panlex_query {
    my ($url, $body) = @_;

    $url = $url =~ m{^/} ? $API_URL . $url : $url;
    my $req = HTTP::Request->new(POST => $url);
    $req->content_type('application/json');
    $req->accept_decodable;
    $req->content(encode_json($body || {}));

    my $ua = LWP::UserAgent->new;
    $ua->timeout(1800);

    my $res = $ua->request($req);

    my $content = $res->decoded_content;

    if ($content ne '') {
        eval { $content = decode_json($content) };
        die $@ if $@;
    }

    if ($res->code == 200) {
        return $content;
    } else {
        if (ref $content) {
            die "PanLex API returned $content->{code}: $content->{message}";
        } else {
            die "PanLex API returned status " . $res->code;
        }
    }
}

# Recursively query the PanLex API until all results are returned.
# Arguments are the same as for panlex_query.
# The result array of the returned value will contain all results,
# and resultNum will reflect the total number of results.
sub panlex_query_all {
    my ($url, $body) = @_;

    # duplicate the body object so we can modify it.
    $body = { %$body };
    delete $body->{limit};
    $body->{offset} = 0;

    my $result;
    while (1) {
        my $this_result = panlex_query($url, $body);

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

#### panlex_query_map
# Iteratively query the PanLex API, mapping input strings to output strings.
# Arguments:
#   0: URL.
#   1: body.
#   2: array key in body.
#   3: key in result object.

sub panlex_query_map {
    my ($url, $body, $b_key, $r_key) = @_;
    my $result;
    my $txt = $body->{$b_key};


    for (my $i = 0; $i < @$txt; $i += $PanLex::Client::ARRAY_MAX) {
        my $last = $i + $PanLex::Client::ARRAY_MAX - 1;
        $last = $#{$txt} if $last > $#{$txt};

        # get the next set of results.
        my $this_result = panlex_query($url, { %$body, $b_key => [@{$txt}[$i .. $last]] });

        # merge with the previous results, if any.
        if ($result) {
            $result->{$r_key} = { %{$result->{$r_key}}, %{$this_result->{$r_key}} };
        }
        else {
            $result = $this_result;
        }
    }

    return $result->{$r_key};
}

#### panlex_norm
# Iteratively query the PanLex api at /norm and return the results.
# Arguments:
#   0: norm type ('expr' or 'definition').
#   1: variety UID.
#   2: txt parameter containing expression texts (arrayref).
#   3: degrade parameter (boolean).
#   4: grp parameter (arrayref).

sub panlex_norm {
    my ($type, $uid, $txt, $degrade, $grp) = @_;

    return panlex_query_map("/norm/${type}/$uid", {
        txt     => $txt,
        grp     => $grp // [],
        degrade => $degrade,
        cache   => 0,
    }, 'txt', 'norm');
}

1;
