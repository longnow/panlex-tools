package DNode::Scrub;
use 5.10.0;
use DNode::Walk;
use warnings;
use strict;

sub new {
    return bless {
        callbacks => {},
        last_id => 0,
    }, shift;
}

sub scrub {
    my $self = shift;
    my $obj = shift;
    
    my %callbacks;
    my $walked = DNode::Walk->new($obj)->walk(sub {
        my $node = shift;
        my $ref = ref $node->value;
        if ($ref eq 'CODE') {
            my $id = $self->{last_id} ++;
            $self->{callbacks}{$id} = $node->value;
            $callbacks{$id} = [ $node->path ];
            $node->update('[Function]');
        }
    });
    
    return { object => $walked, callbacks => \%callbacks };
}

sub unscrub {
    use List::Util qw/first/;
    my $self = shift;
    my $req = shift;
    my $cb = shift;
    
    return DNode::Walk->new($req->{arguments})->walk(sub {
        my $node = shift;
        my $path = [ $node->path ];
        
        my $id = first {
            elementwise_eq($path, $req->{callbacks}{$_})
        } keys %{ $req->{callbacks} };
        
        if (defined $id) {
            $node->update($cb->($id));
        }
    });
}

sub elementwise_eq {
    use List::MoreUtils qw/each_arrayref/;
    my ($xref, $yref) = @_;
    return unless  @$xref == @$yref;

    my $it = each_arrayref($xref, $yref);
    while ( my ($x, $y) = $it->() ) {
        return unless $x eq $y;
    }
    return 1;
}

1;
