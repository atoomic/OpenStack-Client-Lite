package OpenStack::Client::Lite::API::Network;

use strict;
use warnings;

use Test::More;
use Moo;

extends 'OpenStack::Client::Lite::API::Service';
# roles
with    'OpenStack::Client::Lite::Roles::Listable';
with    'OpenStack::Client::Lite::Roles::GetFromId';

has '+name' => ( default => 'network' );
has '+version_prefix' => ( default => 'v2.0' );
has '+version'        => ( default => 'v2' ); # use the v2 specs

sub networks {
    my ( $self, @args ) = @_;

    return $self->_list( ['/networks', 'networks'], \@args );
}

sub security_groups {
    my ( $self, @args ) = @_;

    return $self->_list( ['/security-groups', 'security_groups'], \@args ); 
}


sub floatingips {
	my ( $self, @args ) = @_;

	return $self->_list( ['/floatingips', 'floatingips'], \@args );		
}

sub port_from_uid {
	my ( $self, $uid ) = @_;

	return $self->_get_from_id( '/ports', $uid );
}

# https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
sub ports {
	my ( $self, @args ) = @_;

	return $self->_list( ['/ports', 'ports'], \@args );				
}

# REQ: curl -g -i -X POST http://service01a-c2.cpanel.net:9696/v2.0/floatingips 
# -H "Content-Type: application/json" -H "User-Agent: openstacksdk/0.27.0 keystoneauth1/3.13.1 python-requests/2.21.0 CPython/3.6.6" -H "X-Auth-Token: {SHA256}b0ba0e5595347e63c0b6f56e7f035977abe209f6fa034f41f7dfe491e6e984a1" -d '{"floatingip": {"floating_network_id": "8a10163f-072c-483a-9834-78395cf8a2e7"}}'

sub create_floating_ip {
    my ( $self, $network_id ) = @_;

    die "Missing network_id" unless defined $network_id;

    my $uri = $self->root_uri( '/floatingips' );    
    my $answer = $self->post( $uri, 
        { floatingip => { floating_network_id => $network_id } } 
    );  

    return $answer->{floatingip} if ref $answer && $answer->{floatingip};
    return $answer;
}

sub add_floating_ip_to_server {
    my ( $self, $floatingip_id, $server_id ) = @_;

    die "floatingip_id is required" unless defined $floatingip_id;
    die "server_id is required" unless defined $server_id;

    note "**** add floating ip .... $floatingip_id, $server_id"; 
    my $uri = $self->root_uri( '/ports' );
    my $ports = $self->get( $uri, device_id => $server_id );

    note "Port.... ", explain $ports;
    # pick the first port for now (maybe need to check the network_id...)
    my $port_id = eval { $ports->{ports}->[0]->{id} };
    die "Cannot find a port for server $server_id: $@" unless defined $port_id;

    note "using port: ", $port_id;
    # now link the floating ip to the port

    return $self->put( $self->root_uri( '/floatingips/' . $floatingip_id ), {
        floatingip => { port_id => $port_id }
        } );
}

1;

__END__

#> openstack server add floating ip INSTANCE_ID FLOATING_IP
> openstack server add floating ip ccb22335-c123-4e71-8351-c236b3a54e3f 6e5b0789-a5d8-40a3-a419-0bda90fe399f --debug

1/ GET /v2.0/ports?device_id=INSTANCE_ID
-> ... "id":"7abed84d-786f-43f7-a3ae-8113f93bddf4"

2/ PUT /v2.0/floatingips/FLOATING_IP -H "Content-Type: application/json" -H "User-Agent: openstacksdk/0.27.0 keystoneauth1/3.13.1 python-requests/2.21.0 CPython/3.6.6" -H "X-Auth-Token: {SHA256}33a74191e354ec3eb5ef2636ff2a3cb6410e338298b06b0e125a6668ed771b4b" 
    -d '{"floatingip": {"port_id": "7abed84d-786f-43f7-a3ae-8113f93bddf4"}}'

REQ: curl -g -i -X GET "http://service01a-c2.cpanel.net:9696/v2.0/ports?device_id=ccb22335-c123-4e71-8351-c236b3a54e3f" 
-H "Accept: application/json" -H "User-Agent: openstacksdk/0.27.0 keystoneauth1/3.13.1 python-requests/2.21.0 CPython/3.6.6" -H "X-Auth-Token: {SHA256}33a74191e354ec3eb5ef2636ff2a3cb6410e338298b06b0e125a6668ed771b4b"
http://service01a-c2.cpanel.net:9696 "GET /v2.0/ports?device_id=ccb22335-c123-4e71-8351-c236b3a54e3f HTTP/1.1" 200 823
RESP: [200] Connection: keep-alive Content-Length: 823 Content-Type: application/json Date: Tue, 16 Apr 2019 22:47:50 GMT X-Openstack-Request-Id: req-8a29f6bd-17a8-4f2e-8d9c-b11acda39448
RESP BODY: {"ports":[{"status":"ACTIVE","description":"","allowed_address_pairs":[],"tags":[],"network_id":"fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4","tenant_id":"76fb18aec577491bb676b482f5671352","created_at":"2019-04-16T22:44:59Z","admin_state_up":true,"updated_at":"2019-04-16T22:45:05Z","binding:vnic_type":"normal","device_id":"ccb22335-c123-4e71-8351-c236b3a54e3f","device_owner":"compute:nova","revision_number":10,"mac_address":"fa:16:3e:73:9f:43","id":"7abed84d-786f-43f7-a3ae-8113f93bddf4","project_id":"76fb18aec577491bb676b482f5671352","fixed_ips":[{"subnet_id":"5b1e5c0e-62cc-4d64-ae79-43ce763506c4","ip_address":"172.16.0.3"},{"subnet_id":"a3267fc9-0f73-45e1-9296-cb39805aa2f5","ip_address":"2620:0:28a4:c089:f816:3eff:fe73:9f43"}],"extra_dhcp_opts":[],"security_groups":["6f86e4c2-a498-4f4d-afe9-a2def5ada8c8"],"name":""}]}
GET call to network for http://service01a-c2.cpanel.net:9696/v2.0/ports?device_id=ccb22335-c123-4e71-8351-c236b3a54e3f used request id req-8a29f6bd-17a8-4f2e-8d9c-b11acda39448
REQ: curl -g -i -X PUT http://service01a-c2.cpanel.net:9696/v2.0/floatingips/6e5b0789-a5d8-40a3-a419-0bda90fe399f -H "Content-Type: application/json" -H "User-Agent: openstacksdk/0.27.0 keystoneauth1/3.13.1 python-requests/2.21.0 CPython/3.6.6" -H "X-Auth-Token: {SHA256}33a74191e354ec3eb5ef2636ff2a3cb6410e338298b06b0e125a6668ed771b4b" 
    -d '{"floatingip": {"port_id": "7abed84d-786f-43f7-a3ae-8113f93bddf4"}}'
http://service01a-c2.cpanel.net:9696 "PUT /v2.0/floatingips/6e5b0789-a5d8-40a3-a419-0bda90fe399f HTTP/1.1" 200 547
RESP: [200] Connection: keep-alive Content-Length: 547 Content-Type: application/json Date: Tue, 16 Apr 2019 22:47:51 GMT X-Openstack-Request-Id: req-971a6996-25e5-4f5f-acb1-17efd2cdc5c7
RESP BODY: {"floatingip": {"router_id": "272ff465-c8b9-44e4-9788-7efe25144c83", "status": "DOWN", "description": "", "tags": [], "tenant_id": "76fb18aec577491bb676b482f5671352", "created_at": "2019-04-16T22:45:10Z", "updated_at": "2019-04-16T22:47:50Z", "floating_network_id": "8a10163f-072c-483a-9834-78395cf8a2e7", "fixed_ip_address": "172.16.0.3", "floating_ip_address": "10.1.35.126", "revision_number": 1, "project_id": "76fb18aec577491bb676b482f5671352", "port_id": "7abed84d-786f-43f7-a3ae-8113f93bddf4", "id": "6e5b0789-a5d8-40a3-a419-0bda90fe399f"}}
PUT call to network for http://service01a-c2.cpanel.net:9696/v2.0/floatingips/6e5b0789-a5d8-40a3-a419-0bda90fe399f used request id req-971a6996-25e5-4f5f-acb1-17efd2cdc5c7
clean_up AddFloatingIP:
