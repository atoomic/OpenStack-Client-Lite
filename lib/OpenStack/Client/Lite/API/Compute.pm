package OpenStack::Client::Lite::API::Compute;

use strict;
use warnings;

use Moo;

# use Client::Lite::API role
#with 'OpenStack::Client::Lite::API'; ...

extends 'OpenStack::Client::Lite::API::Service';

# roles
#with    'OpenStack::Client::Lite::Roles::DataAsYaml';
with 'OpenStack::Client::Lite::Roles::Listable';
with 'OpenStack::Client::Lite::Roles::GetFromId';

has '+name' => (default => 'compute');

sub delete_server {
    my ($self, $uid) = @_;

    # first check that the server exists
    my $server = $self->api->server_from_uid($uid);
    return unless ref $server && $server->{id} eq $uid;

    my $api = $self->api;
    {
# delete floating ip for device [maybe provide its own helper at the main level of API]
        my $port_for_device = $api->ports(device_id => $uid);
        if ($port_for_device && $port_for_device->{id}) {

            my $port_id = $port_for_device->{id};
            my $floatingip = $api->floatingips(port_id => $port_id);

            if ($floatingip && $floatingip->{id}) {
                $api->delete_floatingip($floatingip->{id});
            }
        }
    }

    # maybe need to wait?
    my $uri = $self->root_uri('/servers/' . $uid);
    return $self->delete($uri);
}

#  FIXME should be generated from specs
sub create_server {
    my ($self, %opts) = @_;

    my $uri = $self->root_uri('/servers/');
    my $output = $self->post($uri, {server => {%opts}});
    return $output->{server} if ref $output;
    return $output;
}

### helpers

1;
