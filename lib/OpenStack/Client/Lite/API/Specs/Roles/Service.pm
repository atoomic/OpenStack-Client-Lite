package OpenStack::Client::Lite::API::Specs::Roles::Service;

use strict;
use warnings;

use Moo::Role;
use Test::More;

use OpenStack::Client::Lite::Helpers::DataAsYaml;


# FIXME let the specs load from there... usingg 
has 'specs' => ( is => 'ro', lazy => 1, default => sub { 
    my ( $self ) = @_;
    my $specs = OpenStack::Client::Lite::Helpers::DataAsYaml::LoadDataFrom( ref $self ) // {};
    # populate missing keys
    $specs->{$_} //= {} for qw/get post put delete/;

    return $specs; 
    } 
);

sub get {
    my ( $self, $route ) = @_;

    return $self->specs()->{get}->{$route};
}

sub put {
    die "must be implemented";
}

sub post {
    die "must be implemented";
}

sub query_filters_for {
    my ( $self, $method, $route, $args ) = @_;

    die unless defined $method;
    die unless defined $route;
    die unless ref $args eq 'ARRAY';

    return unless @$args % 2;

    my %filters = @$args;

    my $spec = $self->can( $method )->( $self, $route );

    return unless ref $spec eq 'HASH' && ref $spec->{request} && ref $spec->{request}->{query};

    my %valid_filters = map { $_ => 1 } sort keys %{ $spec->{request}->{query} };

    my $use_filters = {};

    foreach my $filter ( sort keys %filters ) {
        next unless defined $valid_filters{ $filter };
        ### ... can use type & co ... 
        $use_filters->{ $filter } = $filters{$filter};
    }
    
    return unless scalar keys %$use_filters;
    return $use_filters;
}

1;