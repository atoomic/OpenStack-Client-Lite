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

like(
    dies { OpenStack::Client::Lite->new() },
    qr/Missing arguments to create Auth object/,
    "Missing arguments to create Auth object");

{
    #local $Test::OpenStack::Client::Lite::UA_DISPLAY_OUTPUT = 1;
    my $api = get_api_object();

    is ref $api->auth, "OpenStack::Client::Auth::v3",
      "OpenStack::Client::Auth::v3";
    is $api->auth->token, "custom-token",
      "auth is aware of the token from headers";

    is [$api->services], [
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
}

done_testing;
