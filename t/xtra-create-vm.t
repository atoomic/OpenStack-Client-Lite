#!/usr/bin/env perl

use strict;
use warnings;

use OpenStack::Client::Lite ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::Client::Lite qw{:all};
use Test::OpenStack::Client::Lite::Auth qw{:all};

use JSON;

mock_lwp_useragent();

$Test::OpenStack::Client::Lite::UA_DISPLAY_OUTPUT = 1;

my $api = get_api_object(use_env => 0);

ok $api, "got one api object" or die;

{
    note "Testing Network service";

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/flavors',
        application_json(json_for_flavors()),
    );

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/networks',
        application_json(json_for_networks()),
    );

    my $IMAGE_UID           = '170fafa5-1329-44a3-9c27-9bb77b77206d';
    my $IMAGE_NAME          = 'myimage';
    my $SERVER_NAME         = "testsuite for OpenStack::Client::Lite";
    my $FLOATING_IP_NETWORK = 'missing network name';

    my $create_vm = sub {
        return $api->create_vm(
            name     => $SERVER_NAME,    # vm name
            image    => $IMAGE_UID,      # image used to create the VM
            flavor   => 'small',
            key_name => 'My SSH Key',
            network  => 'net1',
            network_for_floating_ip => $FLOATING_IP_NETWORK,
        );
    };

    like(
        dies { $create_vm->() },
        qr{Cannot find 'networks' for id/name '$FLOATING_IP_NETWORK'},
        "fail when using an unkown network");

    note "attempt 2";

    $FLOATING_IP_NETWORK = 'net2';

    mock_get_request(
        'http://127.0.0.1:9292/v2/images/170fafa5-1329-44a3-9c27-9bb77b77206d',
        application_json(json_imageid()),
    );

    mock_get_request(
        'http://127.0.0.1:9696/v2.0/security-groups',
        application_json(json_for_security_groups()),
    );

    mock_post_request(
        'http://127.0.0.1:8774/v2.1/servers',
        application_json(json_create_server()),
    );

    mock_get_request(
        'http://127.0.0.1:8774/v2.1/servers/aaaaa-bbbb-ccccc-dddd',
        application_json(json_for_server()),
    );

    $api->create_max_timeout(2);
    $api->create_loop_sleep(1);    # disable sleep

    like(
        dies { $create_vm->() },
        qr{Failed to create server: never came back as active},
        "server does not came back as active");

    note "attempt 3";

    # continue...
    # fist time the server is inactive
    # second time the server is active

}

done_testing;

sub json_for_server {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
{
    "server": {
        "OS-EXT-AZ:availability_zone": "UNKNOWN",
        "OS-EXT-STS:power_state": 0,
        "created": "2018-12-03T21:06:18Z",
        "flavor": {
            "disk": 1,
            "ephemeral": 0,
            "extra_specs": {},
            "original_name": "m1.tiny",
            "ram": 512,
            "swap": 0,
            "vcpus": 1
        },
        "id": "33748c23-38dd-4f70-b774-522fc69e7b67",
        "image": {
            "id": "70a599e0-31e7-49b7-b260-868f441e862b",
            "links": [
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/images/70a599e0-31e7-49b7-b260-868f441e862b",
                    "rel": "bookmark"
                }
            ]
        },
        "status": "UNKNOWN",
        "tenant_id": "project",
        "user_id": "fake",
        "links": [
            {
                "href": "http://openstack.example.com/v2.1/6f70656e737461636b20342065766572/servers/33748c23-38dd-4f70-b774-522fc69e7b67",
                "rel": "self"
            },
            {
                "href": "http://openstack.example.com/6f70656e737461636b20342065766572/servers/33748c23-38dd-4f70-b774-522fc69e7b67",
                "rel": "bookmark"
            }
        ]
    }
}
JSON
}

sub json_create_server {
    return <<'JSON';
{
    "server" : {
        "id": "aaaaa-bbbb-ccccc-dddd",
        "accessIPv4": "1.2.3.4",
        "accessIPv6": "80fe::",
        "name" : "new-server-test",
        "imageRef" : "70a599e0-31e7-49b7-b260-868f441e862b",
        "flavorRef" : "1",
        "availability_zone": "us-west",
        "OS-DCF:diskConfig": "AUTO",
        "metadata" : {
            "My Server Name" : "Apache1"
        },
        "personality": [
            {
                "path": "/etc/banner.txt",
                "contents": "ICAgICAgDQoiQSBjbG91ZCBkb2VzIG5vdCBrbm93IHdoeSBp dCBtb3ZlcyBpbiBqdXN0IHN1Y2ggYSBkaXJlY3Rpb24gYW5k IGF0IHN1Y2ggYSBzcGVlZC4uLkl0IGZlZWxzIGFuIGltcHVs c2lvbi4uLnRoaXMgaXMgdGhlIHBsYWNlIHRvIGdvIG5vdy4g QnV0IHRoZSBza3kga25vd3MgdGhlIHJlYXNvbnMgYW5kIHRo ZSBwYXR0ZXJucyBiZWhpbmQgYWxsIGNsb3VkcywgYW5kIHlv dSB3aWxsIGtub3csIHRvbywgd2hlbiB5b3UgbGlmdCB5b3Vy c2VsZiBoaWdoIGVub3VnaCB0byBzZWUgYmV5b25kIGhvcml6 b25zLiINCg0KLVJpY2hhcmQgQmFjaA=="
            }
        ],
        "security_groups": [
            {
                "name": "default"
            }
        ],
        "user_data" : "IyEvYmluL2Jhc2gKL2Jpbi9zdQplY2hvICJJIGFtIGluIHlvdSEiCg=="
    },
    "OS-SCH-HNT:scheduler_hints": {
        "same_host": "48e6a9f6-30af-47e0-bc04-acaed113bb4e"
    }
}
JSON
}

sub json_imageid {
    return <<'JSON';
{
    "image": {
        "OS-DCF:diskConfig": "AUTO",
        "OS-EXT-IMG-SIZE:size": "74185822",
        "created": "2011-01-01T01:02:03Z",
        "id": "70a599e0-31e7-49b7-b260-868f441e862b",
        "links": [
            {
                "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/images/70a599e0-31e7-49b7-b260-868f441e862b",
                "rel": "self"
            },
            {
                "href": "http://openstack.example.com/6f70656e737461636b20342065766572/images/70a599e0-31e7-49b7-b260-868f441e862b",
                "rel": "bookmark"
            },
            {
                "href": "http://glance.openstack.example.com/images/70a599e0-31e7-49b7-b260-868f441e862b",
                "rel": "alternate",
                "type": "application/vnd.openstack.image"
            }
        ],
        "metadata": {
            "architecture": "x86_64",
            "auto_disk_config": "True",
            "kernel_id": "nokernel",
            "ramdisk_id": "nokernel"
        },
        "minDisk": 0,
        "minRam": 0,
        "name": "fakeimage7",
        "progress": 100,
        "status": "ACTIVE",
        "updated": "2011-01-01T01:02:03Z"
    }
}
JSON
}

sub json_for_networks {
    return <<'JSON';
{
    "networks": [
        {
            "admin_state_up": true,
            "availability_zone_hints": [],
            "availability_zones": [
                "nova"
            ],
            "created_at": "2016-03-08T20:19:41",
            "dns_domain": "my-domain.org.",
            "id": "d32019d3-bc6e-4319-9c1d-6722fc136a22",
            "ipv4_address_scope": null,
            "ipv6_address_scope": null,
            "l2_adjacency": false,
            "mtu": 1500,
            "name": "net1",
            "port_security_enabled": true,
            "project_id": "4fd44f30292945e481c7b8a0c8908869",
            "qos_policy_id": "6a8454ade84346f59e8d40665f878b2e",
            "revision_number": 1,
            "router:external": false,
            "shared": false,
            "status": "ACTIVE",
            "subnets": [
                "54d6f61d-db07-451c-9ab3-b9609b6b6f0b"
            ],
            "tenant_id": "4fd44f30292945e481c7b8a0c8908869",
            "updated_at": "2016-03-08T20:19:41",
            "vlan_transparent": true,
            "description": "",
            "is_default": false
        },
        {
            "admin_state_up": true,
            "availability_zone_hints": [],
            "availability_zones": [
                "nova"
            ],
            "created_at": "2016-03-08T20:19:41",
            "dns_domain": "my-domain.org.",
            "id": "db193ab3-96e3-4cb3-8fc5-05f4296d0324",
            "ipv4_address_scope": null,
            "ipv6_address_scope": null,
            "l2_adjacency": false,
            "mtu": 1500,
            "name": "net2",
            "port_security_enabled": true,
            "project_id": "26a7980765d0414dbc1fc1f88cdb7e6e",
            "qos_policy_id": "bfdb6c39f71e4d44b1dfbda245c50819",
            "revision_number": 3,
            "router:external": false,
            "shared": false,
            "status": "ACTIVE",
            "subnets": [
                "08eae331-0402-425a-923c-34f7cfe39c1b"
            ],
            "tenant_id": "26a7980765d0414dbc1fc1f88cdb7e6e",
            "updated_at": "2016-03-08T20:19:41",
            "vlan_transparent": false,
            "description": "",
            "is_default": false
        }
    ]
}
JSON
}

sub json_for_security_groups {
    return <<JSON;
{
    "security_groups": [
        {
            "description": "default",
            "id": "85cc3048-abc3-43cc-89b3-377341426ac5",
            "name": "default",
            "security_group_rules": [
                {
                    "direction": "egress",
                    "ethertype": "IPv6",
                    "id": "3c0e45ff-adaf-4124-b083-bf390e5482ff",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": null,
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "egress",
                    "ethertype": "IPv4",
                    "id": "93aa42e5-80db-4581-9391-3a608bd0e448",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": null,
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 2,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "ingress",
                    "ethertype": "IPv6",
                    "id": "c0b09f00-1d49-4e64-a0a7-8a186d928138",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                },
                {
                    "direction": "ingress",
                    "ethertype": "IPv4",
                    "id": "f7d45c89-008e-4bab-88ad-d6811724c51c",
                    "port_range_max": null,
                    "port_range_min": null,
                    "protocol": null,
                    "remote_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "remote_ip_prefix": null,
                    "security_group_id": "85cc3048-abc3-43cc-89b3-377341426ac5",
                    "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "revision_number": 1,
                    "tags": ["tag1,tag2"],
                    "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550",
                    "created_at": "2018-03-19T19:16:56Z",
                    "updated_at": "2018-03-19T19:16:56Z",
                    "description": ""
                }
            ],
            "project_id": "e4f50856753b4dc6afee5fa6b9b6c550",
            "revision_number": 8,
            "created_at": "2018-03-19T19:16:56Z",
            "updated_at": "2018-03-19T19:16:56Z",
            "tags": ["tag1,tag2"],
            "tenant_id": "e4f50856753b4dc6afee5fa6b9b6c550"
        }
    ]
}
JSON
}

sub json_for_flavors {
    return <<'JSON';
{
    "flavors": [
        {
            "id": "1",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/1",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/1",
                    "rel": "bookmark"
                }
            ],
            "name": "tiny",
            "description": null
        },
        {
            "id": "2",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/2",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/2",
                    "rel": "bookmark"
                }
            ],
            "name": "small",
            "description": null
        },
        {
            "id": "3",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/3",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/3",
                    "rel": "bookmark"
                }
            ],
            "name": "medium",
            "description": null
        },
        {
            "id": "4",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/4",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/4",
                    "rel": "bookmark"
                }
            ],
            "name": "large",
            "description": null
        },
        {
            "id": "5",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/5",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/5",
                    "rel": "bookmark"
                }
            ],
            "name": "xlarge",
            "description": null
        },
        {
            "id": "6",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/6",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/6",
                    "rel": "bookmark"
                }
            ],
            "name": "tiny.specs",
            "description": null
        },
        {
            "id": "7",
            "links": [
                {
                    "href": "http://openstack.example.com/v2/6f70656e737461636b20342065766572/flavors/7",
                    "rel": "self"
                },
                {
                    "href": "http://openstack.example.com/6f70656e737461636b20342065766572/flavors/7",
                    "rel": "bookmark"
                }
            ],
            "name": "small.description",
            "description": "test description"
        }
    ]
}
JSON
}

sub json_for_floatingips {

# https://developer.openstack.org/api-ref/compute/?expanded=show-server-details-detail
    return <<'JSON';
{
    "floatingips": [
        {
            "router_id": "d23abc8d-2991-4a55-ba98-2aaea84cc72f",
            "description": "for test",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip",
            "created_at": "2016-12-21T10:55:50Z",
            "updated_at": "2016-12-21T10:55:53Z",
            "revision_number": 1,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": "10.0.0.3",
            "floating_ip_address": "172.24.4.228",
            "port_id": "ce705c24-c1ef-408a-bda3-7bbd946164ab",
            "id": "2f245a7b-796b-4f26-9cf9-9e82d248fda7",
            "status": "ACTIVE",
            "port_details": {
                "status": "ACTIVE",
                "name": "",
                "admin_state_up": true,
                "network_id": "02dd8479-ef26-4398-a102-d19d0a7b3a1f",
                "device_owner": "compute:nova",
                "mac_address": "fa:16:3e:b1:3b:30",
                "device_id": "8e3941b4-a6e9-499f-a1ac-2a4662025cba"
            },
            "tags": ["tag1,tag2"],
            "port_forwardings": []
        },
        {
            "router_id": null,
            "description": "for test",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip2",
            "created_at": "2016-12-21T11:55:50Z",
            "updated_at": "2016-12-21T11:55:53Z",
            "revision_number": 2,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": null,
            "floating_ip_address": "172.24.4.227",
            "port_id": null,
            "id": "61cea855-49cb-4846-997d-801b70c71bdd",
            "status": "DOWN",
            "port_details": null,
            "tags": ["tag1,tag2"],
            "port_forwardings": []
        },
        {
            "router_id": "0303bf18-2c52-479c-bd68-e0ad712a1639",
            "description": "for test with port forwarding",
            "dns_domain": "my-domain.org.",
            "dns_name": "myfip3",
            "created_at": "2018-06-15T02:12:48Z",
            "updated_at": "2018-06-15T02:12:57Z",
            "revision_number": 1,
            "project_id": "4969c491a3c74ee4af974e6d800c62de",
            "tenant_id": "4969c491a3c74ee4af974e6d800c62de",
            "floating_network_id": "376da547-b977-4cfe-9cba-275c80debf57",
            "fixed_ip_address": null,
            "floating_ip_address": "172.24.4.42",
            "port_id": null,
            "id": "898b198e-49f7-47d6-a7e1-53f626a548e6",
            "status": "ACTIVE",
            "tags": [],
            "port_forwardings": [
                {
                    "protocol": "tcp",
                    "internal_ip_address": "10.0.0.19",
                    "internal_port": 25,
                    "external_port": 2225
                },
                {
                    "protocol": "tcp",
                    "internal_ip_address": "10.0.0.18",
                    "internal_port": 16666,
                    "external_port": 8786
                }
            ]
        }
    ]
}
JSON
}

__END__
