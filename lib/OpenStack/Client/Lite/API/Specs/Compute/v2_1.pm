package OpenStack::Client::Lite::API::Specs::Compute::v2_1;

use strict;
use warnings;

use Moo;

with 'OpenStack::Client::Lite::API::Specs::Roles::Service';

1;

#
# API specs: incomplete need to be continued
# url:
#   https://developer.openstack.org/api-ref/network/v2/index.html?expanded=list-ports-detail#ports
#

__DATA__
---
get:
  /servers/{server_id}:
    perl_api:
      method: server_from_uid
      type: getfromid
      uid: '{server_id}'
    request:
      path:
        server_id:
          required: 1
  /servers:
    perl_api:
      method: servers
      type: listable
      listable_key: 'servers'
    request:
      query:
        host: {}
        flavor: {}
        hostname: {}
        image: {}
        ip: {}
  /flavors:
    perl_api:
      method: flavors
      type: listable
      listable_key: 'flavors'
    request:
      query:
        sort_key: {}
        sort_dir: {}
        limit: {}
        marker: {}
        minDisk: {}
        minRam: {}
        isPublic: {}
  /os-keypairs:
    perl_api:
      method: keypairs
      type: listable
      listable_key: 'keypairs'
    request:
      query:
        user_id: {}
        limit: {}
        marker: {}
delete:
  /server/{server_id}:
    perl_api:
      method: delete_server_from_uid
      type: getfromid
      uid: '{server_id}'
    request:
      path:
        server_id:
          required: 1
