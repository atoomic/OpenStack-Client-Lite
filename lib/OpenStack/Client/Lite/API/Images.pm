package OpenStack::Client::Lite::API::Images;

use strict;
use warnings;

use Test::More;
use Moo;


extends 'OpenStack::Client::Lite::API::Service';
# roles
with    'OpenStack::Client::Lite::Roles::Listable';

has '+name' => ( default => 'image' );
has '+version_prefix' => ( default => 'v2' );

=pod

Note loading all images can be very slow 
as we have to use multiple requests (kind of pagination)...
and can result to require more than 50 requests...

For this reason we would prefer selecting one image
either by its 'exact name' or its 'UID'

=cut

sub images {
    my ( $self, @args ) = @_;

    die "Please use image_from_uid image_from_name";
    #return $self->_list( ['/os-keypairs', 'keypairs'], \@args );
#note "DATA: ", explain $self->DataAsYaml;
}

# API doc
# https://developer.openstack.org/api-ref/image/v2/?expanded=list-images-detail

sub image_from_uid {
    my ( $self, $uid ) = @_;

    die unless defined $uid;

    my $uri = $self->root_uri( '/images/' . $uid );
    
    return $self->get( $uri );
}


sub image_from_name {
    my ( $self, $name ) = @_;

# v2/images?name=in:"glass,%20darkly"

    die unless defined $name;

    my $uri = $self->root_uri( '/images' );
    
    my $reply = $self->get( $uri, name => qq{in:"$name"} );

    return unless ref $reply && $reply->{images};

    my $images = $reply->{images};

    return unless ref $images;

    if ( scalar @$images > 1 ) {
        warn "image_from_name: more than one image sharing the same name '$name'";
        return $images;
    }

    return $images->[0];
}

### helpers


1;

__DATA__
---
keypairs:
  listable: 1
flavors:
  listable: 1



