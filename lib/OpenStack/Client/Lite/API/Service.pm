package OpenStack::Client::Lite::API::Service;

use strict;
use warnings;

use Test::More;
use Moo;

has 'auth' => ( is => 'ro', required => 1 );
has 'name' => ( is => 'ro', required => 1 );
has 'region' => ( is => 'ro', required => 1 );

has 'interface' => ( is => 'ro', default => 'public' ); # admin internal or public

has 'client' => ( is => 'ro', lazy => 1, default => sub {
    my ( $self ) = @_;
    
    return $self->auth->service( 
        $self->name, 
        region => $self->region, 
        interface => $self->interface 
     );
},
    handles => [ qw/endpoint get put post delete/ ]

);

has 'api_specs' => ( is => 'ro', lazy => 1, default => \&BUILD_api_specs );

## FIXME: this needs a refactor...
#   idea always strip the version from endpoint so we can add it to the uri later..
#   this would make uri consistent... and improve root_uri
has 'version' => ( 'is' => 'ro', lazy => 1, default => \&BUILD_version );
has 'version_prefix' => ( 'is' => 'ro' ); # added to very routes [optional]

sub BUILD_version {
    my ( $self ) = @_;
    
    my $url = $self->client->endpoint;
    note "BUILD_version.... ", $url;
    if ( $url =~ m{/(v[0-9\.]+)} ) {
        return $1;
    }
    return 'default';
}

sub BUILD_api_specs { # load specs
    my ( $self ) = @_;

    my $pkg = 'OpenStack::Client::Lite::API::Specs::' # .
        . ucfirst( $self->name )  # .
        . '::' . $self->version;

    my $load = eval qq{ require $pkg; 1 };
    if ( $load ) {
        return $pkg->new();
    }

    # default void specs [ undefined ]
    #   we do not have to define all specs for now
    return OpenStack::Client::Lite::API::Specs::Default->new();
}

sub root_uri {
    my ( $self, $uri ) = @_;

    return unless defined $uri;

    return $uri if $uri =~ m{^v}; # already contains a version

    # endpoint already contains a version
    return if $self->endpoint && $self->endpoint =~ m{:[\d]/v}a;

    # append our prefix to the endpoint
    if ( $self->version_prefix ) {
        my $base = $self->version_prefix;
        $base .= '/' unless $uri =~ m{^/};
        $base .= $uri;
        return $base;
    }

    return $uri;
}


1;
