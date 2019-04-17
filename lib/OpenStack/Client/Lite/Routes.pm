package OpenStack::Client::Lite::Routes;

use strict;
use warnings;

use Test::More;
use Moo;

use OpenStack::Client::Lite::API ();
use YAML::XS;

use OpenStack::Client::Lite::Helpers::DataAsYaml;

has 'auth' => (
    is      => 'ro',
    #required => 1,
);

our $ROUTES;

sub init_once {
    $ROUTES //= OpenStack::Client::Lite::Helpers::DataAsYaml::LoadData();
}

# cannot read from data block at compile time
INIT { init_once() }

sub list_all {  
    init_once();
    return sort keys %$ROUTES;
}

sub DESTROY {
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ( @args ) = @_;
    my $call_for = $AUTOLOAD;

    $call_for =~ s/.*:://;

    if ( my $route = $ROUTES->{$call_for} ) {
        note "calling from AUTOLOAD.... ", $call_for;
        die "$call_for is a method call" unless ref $args[0] eq __PACKAGE__;
        my $self = shift @args;

        my $service = $self->service( 
            $route->{service}           
        );

        my $controller = $service->can($call_for) or die "Invalid route '$call_for' for service '".ref($service)."'";

        return $controller->( $service, @args );

        #return $service->dispatch( $call_for, @args );
    }

    die "Unknown function $call_for from AUTOLOAD";
}

sub service {
    my ( $self, $name ) = @_;

    # cache the service once
    my $k = '_service_' . $name;
    if ( ! $self->{$k} ) {
        note "*** get_service.... ", $name;
        $self->{$k} = OpenStack::Client::Lite::API::get_service( 
            name => $name, auth => $self->auth, region => $ENV{'OS_REGION_NAME'}
        );
    }   

    return $self->{$k};
}

1;

## this data block describes the routes
#   this could be moved to a file...
__DATA__
---
keypairs:
  service: compute
flavors:
  service: compute
servers:
  service: compute
delete_server:
  service: compute
server_from_uid:
  service: compute
create_server:
  service: compute
networks:
  service: network
add_floating_ip_to_server:
  service: network
floatingips:
  service: network
ports:
  service: network
port_from_uid:  
  service: network
security_groups:
  service: network
create_floating_ip:
  service: network
image_from_uid:
  service: images
image_from_name:
  service: images


