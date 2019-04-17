package OpenStack::Client::Lite::Roles::GetFromId;

use strict;
use warnings;

use Moo::Role;

### FIXME to delete once unused, should prefer the other flavor
sub _get_from_id {
    my ($self, $route, $id) = @_;

    die "route must be defined when using get_from_id" unless defined $route;
    die "invalid route '$route' - must starts with /"  unless $route =~ m{^/};
    die "Undefined 'id' for route '$route'"            unless defined $id;

    $route .= '/' unless $route =~ m{/$};

    my $uri    = $self->root_uri($route . $id);
    my $answer = $self->get($uri);

    if (ref $answer eq 'HASH' && scalar keys %$answer == 1) {
        my ($mainkey) = keys %$answer;
        return $answer->{$mainkey};
    }

    return $answer;
}

sub _get_from_id_spec {
    my ($self, $route, $id) = @_;

    die "route must be defined when using get_from_id" unless defined $route;
    die "invalid route '$route' - must starts with /"  unless $route =~ m{^/};
    die "Undefined 'id' for route '$route'"            unless defined $id;

    $route .= '/' unless $route =~ m{/$};

    #my $uri = $self->root_uri( $route );

    my $answer = $self->get($route);

    if (ref $answer eq 'HASH' && scalar keys %$answer == 1) {
        my ($mainkey) = keys %$answer;
        return $answer->{$mainkey};
    }

    return $answer;
}

1;
