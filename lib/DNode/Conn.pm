package DNode::Conn;
use DNode::Scrub;
use warnings;
use strict;

sub new {
    my $class = shift;
    my $self;
    my %args = @_;
    $args{scrub} = DNode::Scrub->new($args{handle});
    
    my $handler; $handler = sub {
        my ($h, $json) = @_;
        $self->handle($json);
        $h->push_read(json => $handler);
    };
    $args{handle}->push_read(json => $handler);
    
    $self = bless \%args, $class;
    return $self;
}

sub handle {
    my $self = shift;
    my $req = shift;
    my $args = $self->{scrub}->unscrub($req, sub {
        my $id = shift;
        return sub { $self->request($id, @_ ) };
    });
    
    if ($req->{method} =~ m/^\d+$/) {
        my $id = $req->{method};
        $self->{scrub}{callbacks}{$id}(@$args);
    }
    elsif ($req->{method} eq 'methods') {
        $self->{remote} = $args->[0];
        $self->{block}($self->{remote});
    }
}

sub request {
    my $self = shift;
    my ($method, @args) = @_;
    my $scrub = $self->{scrub}->scrub(\@args);
    $self->{handle}->push_write(json => {
        method => $method =~ m/^\d+$/ ? int $method : $method,
        arguments => $scrub->{object},
        callbacks => $scrub->{callbacks},
        links => [],
    });
    $self->{handle}->push_write("\n");
}

1;
