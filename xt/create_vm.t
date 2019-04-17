#!perl

use strict;
use warnings;
use OpenStack::Client::Lite ();

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use OpenStack::Client ();

note "enabling debug for OpenStack::Client";
OpenStack::Client::enable_debug();

my $VALID_ID = match qr{^[a-f0-9\-]+$};

my $IMAGE_UID  = '170fafa5-1329-44a3-9c27-9bb77b77206d';
my $IMAGE_NAME = 'myimage';

# name of the VM we are creating as part of this testsuite
#my $SERVER_NAME = 'testsuite autobuild c7 11.81.9999.42';
my $SERVER_NAME = 'testsuite OpenStack::Client::Lite';

SKIP: {
    skip "OS_AUTH_URL unset, please source one openrc.sh file before."
        unless $ENV{OS_AUTH_URL};

    my $endpoint = $ENV{OS_AUTH_URL} or die "Missing OS_AUTH_URL";

    my $api = OpenStack::Client::Lite->new(
        $endpoint,
        'username' => $ENV{'OS_USERNAME'},
        'password' => $ENV{'OS_PASSWORD'},
        version    => 3,
        scope      => {
            project => {
                name   => $ENV{'OS_PROJECT_NAME'},
                domain => { id => 'default' },
            }
            }

    );

    {
        
        #my $floatingip = $api->floatingips( floating_ip_address => '10.1.35.246' );
        #note "Floating IPs", explain $floatingip;         

        note "Port for a device... ", 
            explain [ $api->ports( device_id => '42147502-68f1-41f8-a764-ada8dae81d65' ) ]; 
        #my $port = $api->port_from_uid( $floatingip->{port_id} );
        #note explain $port;

    }

    exit;

    {
        note "Security groups";

        my @groups = $api->security_groups();
        ok scalar @groups, "security_groups returns some values";

        my $valid_group = hash {
            field created_at => D();
            field updated_at => D();
            field id         => $VALID_ID;
            field name       => D();
            etc;
        };

        foreach my $g (@groups) {
            is $g, $valid_group, "security_groups return a valid group entry";
        }

        my $group = $api->security_groups( name => 'default' );
        is $group, $valid_group, "security_groups by name";
    }

    {
        note "Testing images";

        my $image = $api->image_from_uid($IMAGE_UID);
        is $image, hash {
            field id   => $IMAGE_UID;
            field name => $IMAGE_NAME;
            etc;
        }, "image_from_uid $IMAGE_UID returns one image"
            or die "Cannot find image from UID $IMAGE_UID";

        my $image_from_name = $api->image_from_name($IMAGE_NAME);
        like $image_from_name, $image, "image_from_name $IMAGE_NAME";
    }

    is( $api,
        object {
            prop blessed => 'OpenStack::Client::Lite';

            field auth => object {
                prop blessed => 'OpenStack::Client::Auth::v3';
            };
            field route => object {
                prop blessed => 'OpenStack::Client::Lite::Routes';
            };
            field debug => 0;
            end;
        },
        "can create OpenStack::Client::Lite object"
    ) or die;

    is [ $api->services ], [
        'compute',
        'identity',
        'image',
        'network',
        'placement',
        'volume',
        'volumev2',
        'volumev3'
        ],
        "list os services from auth object";

    #note explain $api->auth->catalog;

    #   note explain $api->flavors();
    {
        note "======= get a single flavor";
        my $small = $api->flavors( name => 'small' );
        note explain $small;
        is $small => hash {
            field name  => 'small';
            field links => D();
            field id    => $VALID_ID;
            end;
        }, "get a flavor 'small'";
    }

    {
        note "======= get all flavors";
        my @flavors = $api->flavors();
        ok scalar @flavors > 1, "got more than one flavor";
        foreach my $flavor (@flavors) {
            is $flavor => hash {
                field name  => D();
                field links => D();
                field id    => $VALID_ID;
                end;
            }, "got flavor " . ( $flavor->{name} // 'undef' );
        }
    }

    {
        note "======= testing networks";

        my @networks = $api->networks();
        ok scalar @networks, "got some networks";

        my $valid_network = hash {
            field created_at => D();
            field updated_at => D();
            field id         => $VALID_ID;
            field project_id => $VALID_ID;
            field name       => D();
            field subnets    => D();
            etc;
        };

        is $networks[0], $valid_network,
            "network has some expected information";

        my $id = $networks[0]->{id};
        my $network = $api->networks( id => $id );
        is $network, $valid_network, "network from id looks valid";
        is $network->{id}, $id, "network id match";

        my $network_by_name
            = $api->networks( name => 'Dev Infra initial gre network' );
        if ($network_by_name) {
            is $network_by_name, $valid_network, "got a network by name";

            my $network_by_name_regex
                = $api->networks( name => qr{^Dev Infra} );

            ## subnets are not sorted... and can come in a random order
            $network_by_name->{subnets}       = [];
            $network_by_name_regex->{subnets} = [];

            like $network_by_name_regex, $network_by_name,
                "can get a network using a regex for the name";

        }
    }

    note "delete_test_servers before creating a new one";
    delete_test_servers($api);

    {
        note "create a VM...";

        my $vm = $api->create_vm(
            name     => $SERVER_NAME,        # vm name
            image    => $IMAGE_UID,          # image used to create the VM
            flavor   => 'small',
            key_name => 'openStack nico',    # optional key to set
              #security_group => 'default', # security group to use, by default use 'default'
            network => 'Dev Infra initial gre network', # network group to use
                 # or network  => qr{Dev Infra}',
                 # or network  => 'fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4 ',

            #--network fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4
            #wait => 1,
            network_for_floating_ip => 'vlan3340-product',

        );
    }

    note "delete_test_servers after test";

    #delete_test_servers( $api );
    #note explain $api;

}
done_testing;

sub delete_test_servers {
    my ($api) = @_;

    my @servers = $api->servers( name => $SERVER_NAME );
    foreach my $server (@servers) {
        next unless defined $server->{id} && length $server->{id};
        note "delete server - ", "id: ", $server->{id}, " ; name: ",
            $server->{name};
        note explain $api->delete_server( $server->{id} );
    }

    return;
}

__END__

TODO 
- check answer from add_floating_ip_to_server
- use GetFromId role in more locations
- add the ip to the answer from create_vm
- tidy
- cleanup
- remove some note
- split the unit test
- divide the module
- move all modules to OpenStack::Client::API::Lite
- submit PR to OpenStack::Client
... 

http://service01a-c2.cpanel.net:8774/v2.1/os-keypairs
    
> openstack server create 
    --image 170fafa5-1329-44a3-9c27-9bb77b77206d 
    --flavor small 
    --key-name 'openStack nico' 
    --security-group default 
    --network fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4 
    --wait testFromAPI2 
    --debug

REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:8774/v2.1/flavors -H "Accept: application/json" -H "User-Agent: p
REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:8774/v2.1/flavors/1ffe5704-06e5-4c2d-828c-496a06f477a4 -H "Accept
REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:9696/v2.0/networks/fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4 -H "User-
REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:9696/v2.0/security-groups/default -H "User-Agent: openstacksdk/0.
REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:9696/v2.0/security-groups -H "Accept: application/json" -H "User-
REQ: curl -g -i -X POST http://service01a-c2.cpanel.net:8774/v2.1/servers -H "Accept: application/json" -H "Content-Type
REQ: curl -g -i -X POST http://service01a-c2.cpanel.net:8774/v2.1/servers -H "Accept: application/json" 
    -H "Content-Type: application/json" -H "User-Agent: python-novaclient" 
    -H "X-Auth-Token: {SHA256}2a39527dd72e1c2bf48cf33883e87c18a81d12e46d1d55e5ece4f8f1437fb3a8" 
    -H "X-OpenStack-Nova-API-Version: 2.1" 
    -d '{"server": {
                        "name": "testFromAPI2", 
                        "imageRef": "170fafa5-1329-44a3-9c27-9bb77b77206d", 
                        "flavorRef": "1ffe5704-06e5-4c2d-828c-496a06f477a4", 
                        "key_name": "openStack nico", 
                        "min_count": 1, 
                        "max_count": 1, 
                        "security_groups": [{"name": "6f86e4c2-a498-4f4d-afe9-a2def5ada8c8"}], 
                        "networks": [{"uuid": "fb5c81fd-0a05-46bc-8a7e-cb94dc851bb4"}]
                    }
        }'

REQ: curl -g -i -X GET http://service01a-c2.cpanel.net:8774/v2.1/servers/6ac4b745-1501-46a8-9533-56e0a88ee3a1 -H "Accept
... [ multiple times ?? /// wait ]

