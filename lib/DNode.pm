package DNode;
use 5.10.0;
use strict;
use warnings;

our $VERSION = '0.03';

use AnyEvent::Socket qw/tcp_connect tcp_server/;
use AnyEvent::Handle;
use AnyEvent::TLS;
use DNode::Conn;

sub new {
    my $class = shift;
    my $ctr = shift;
    return bless {
        constructor => $ctr,
        events => {},
        remote => {},
        callbacks => {},
        last_id => 0,
    }, $class;
}

sub on {
    my $self = shift;
    my $events = $self->{events};
}

sub connect {
    use List::Util qw/first/;
    my $self = shift;
    my $host = (first { ref eq '' and !/^\d+$/ } @_) // 'localhost';
    my $port = first { ref eq '' and m/^\d+$/ } @_ or die 'No port specified';
    my $block = (first { ref eq 'CODE' } @_) // sub { };
    
    my $kwargs = (first { ref eq 'HASH' } @_) // {};
    if ($kwargs->{ssl}) {
        $kwargs->{tls} = 'connect';
        $kwargs->{tls_ctx} //= { verify => 0 }
    }

    my $cv = AnyEvent->condvar;
    tcp_connect $host, $port, sub { $self->_handle(shift, $block, $kwargs) };
    $cv->recv;
}

sub listen {
    my $self = shift;
    my $host = first { ref eq '' and !/^\d+$/ } @_;
    my $port = first { ref eq '' and m/^\d+$/ } @_ or die 'No port specified';
    my $block = (first { ref eq 'CODE' } @_) // sub { };

    my $kwargs = (first { ref eq 'HASH' } @_) // {};
    if ($kwargs->{ssl}) {
        die 'No certificate specified or cert could not be read'
            unless -r $kwargs->{cert_file};
        $kwargs->{tls} = 'accept';
        $kwargs->{tls_ctx} = { cert_file => $kwargs->{cert_file} }
    }
    
    my $cv = AnyEvent->condvar;
    tcp_server $host, $port, sub { $self->_handle(shift, $block, $kwargs) };
    $cv->recv;
}

sub _handle {
    my ($self, $fh, $block, $kwargs) = @_;
    my $handle = new AnyEvent::Handle(
        fh => $fh,
        on_error => sub {
            my ($handle, $fatal, $msg) = @_;
            if ($self->{events}{error}) {
                $self->{events}{error}->($msg);
            }
            else {
                die $msg if $fatal;
            }
        },
        ($kwargs->{ssl} ? 
            ((defined $kwargs->{tls} ? $kwargs->{tls} : ()),
            (defined $kwargs->{tls_ctx} ? $kwargs->{tls_ctx} : ()))
            : ()),
    );
    my $conn = DNode::Conn->new(handle => $handle, block => $block);
    
    $conn->request('methods', ref $self->{constructor} eq 'CODE'
        ? $self->{constructor}($self->{remote}, $conn)
        : $self->{constructor}
    );
}

1;
