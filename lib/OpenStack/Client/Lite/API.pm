package OpenStack::Client::Lite::API;

use strict;
use warnings;

#use Moo::Role;
#use Moo;

sub get_service {
    my (%opts) = @_;

    my $name = $opts{name}      or die "name required";
    my $auth = ref($opts{auth}) or die "auth required";

    my $pkg = ucfirst $name;
    $pkg = __PACKAGE__ . "::$pkg";

    eval qq{ require $pkg; 1 } or die "Failed to load $pkg: $@";

    delete $opts{name};

    return $pkg->new(%opts);
}

1;
