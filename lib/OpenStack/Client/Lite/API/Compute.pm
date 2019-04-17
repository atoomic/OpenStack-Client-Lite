package OpenStack::Client::Lite::API::Compute;

use strict;
use warnings;

use Test::More;
use Moo;

# FIXME import LoadData / DataAsYaml
#use OpenStack::Client::Lite::Helpers::DataAsYaml;

# use Client::Lite::API role
#with 'OpenStack::Client::Lite::API'; ...

extends 'OpenStack::Client::Lite::API::Service';
# roles
#with    'OpenStack::Client::Lite::Roles::DataAsYaml';
with    'OpenStack::Client::Lite::Roles::Listable';

has '+name' => ( default => 'compute' );

# with 'OpenStack::Client::Lite::Roles::Dispatchable';
# sub dispatch { # move to a role OpenStack::Client::Lite::Roles::Dispatchable
#   my ( $self, @args ) = @_;
#   note "dispatch... ", explain \@args;
# }

sub keypairs {
    my ( $self, @args ) = @_;

    return $self->_list( ['/os-keypairs', 'keypairs'], \@args );
    #note "DATA: ", explain $self->DataAsYaml;
}

sub servers {
    my ( $self, @args ) = @_;

    return $self->_list( ['/servers', 'servers'], \@args );
}

sub server_from_uid { # by uid
    my ( $self, $uid ) = @_;

    die unless defined $uid;
    my $uri = $self->root_uri( '/servers/' . $uid );
    
    my $answer = $self->get( $uri );

    return $answer->{server} if ( ref $answer && $answer->{server} );
    return $answer;
}

sub delete_server {
    my ( $self, $uid ) = @_;

    # first check that the server exists
    my $server = $self->server_from_uid( $uid );
    return unless ref $server && $server->{id} eq $uid;

    # FIXME destroy the floating IP...

    # DELETE http://service01a-c2.cpanel.net:8774/v2.1/servers/9fcfa8d2-94b0-4749-be7b-e688139fb6d2 -H "Acc

    # maybe need to wait?
    my $uri = $self->root_uri( '/servers/' . $uid );
    return $self->delete( $uri );
}

sub flavors {
    my ( $self, @args ) = @_;

    return $self->_list( ['/flavors', 'flavors'], \@args );
}

sub create_server {
    my ( $self, %opts ) = @_;

    my $uri = $self->root_uri( '/servers/' );   
    return $self->post( $uri, { server => { %opts } } );    
}

### helpers


1;

__DATA__
---
keypairs:
  listable: 1
flavors:
  listable: 1



