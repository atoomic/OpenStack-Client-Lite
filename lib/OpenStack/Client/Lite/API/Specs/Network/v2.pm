package OpenStack::Client::Lite::API::Specs::Network::v2;

use strict;
use warnings;

use Moo;
use Test::More;

with 'OpenStack::Client::Lite::API::Specs::Roles::Service';

# ... test
my $specs = OpenStack::Client::Lite::API::Specs::Network::v2->new();
note explain $specs->get('/v2.0/ports');

#note explain [ OpenStack::Client::Lite::API::Specs::Network::v2->new()->specs() ];

1;

#
# API specs: incomplete need to be continued
# url:
#   https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
#

__DATA__
---
get:
  /v2.0/ports:
    request:
      query:
        admin_state_up:
          type: boolean
        binding:host_id: {}
        description: {}
        device_id: {}
        device_owner: {}
        fixed_ips: {}
        id: {}
        ip_allocation: {}
        mac_address: {}
        name: {}
        network_id: {}
        prokect_id: {}
        revision_number: {}
        sort_dir: {}
        sort_key: {}
        status: {}
        tenant_id: {}
        tags: {}
        tags-any: {}
        not-tags: {}
        not-tags-any: {}
        fields: {}
        mac_learning_enabled:
          type: boolean
put:
  /v2.0/ports/{port_id}:
    request:
      path:
        port_id:
          required: 1
      body:
        port:
          required: 1
        admin_state_up: {}
        allowed_address_pairs:
          type: array
        binding:host_id: {}
        binding:profile:
          type: object
        binding:vnic_type: {}
        data_plane_status: {}
        description: {}
        device_id: {}
        device_owner: {}
        dns_domain: {}
        dns_name: {}
        extra_dhcp_opts: 
          type: array
