package PanLex::Server;
use strict;
use warnings 'FATAL', 'all';
use utf8;
use Mojo::Base 'Mojolicious';
use PanLex::Normalize;

sub startup {
    my $app = shift;

    $app->routes->post('/normalize/:method')->to('main#normalize');
}

package PanLex::Server::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';

sub normalize {
    my $c = shift;
    my $method = $c->param('method');
    my $args = $c->req->json;

    my $result = PanLex::Normalize->$method(@$args);

    $c->render(json => $result);
}

1;