package OpenStack::Client::Lite::Roles::Listable;

use strict;
use warnings;

use Test::More;
use Moo::Role;

sub _list {
    my ( $self, $all_args, $caller_args ) = @_;

    # all_args are arguments from the internal OpenStack::Client::Lite::API
    # caller_args are coming from the user to filter the results
    #   if some filters are also arguments to the request
    #   then appending them to the query will shorten the output and run it faster

    my @all;
    {
        my ( $uri, @extra ) = @$all_args;
        $uri = $self->root_uri( $uri );


        my $extra_filters = $self->api_specs()->query_filters_for( '/get', $uri, $caller_args );

        if ( $extra_filters ) {
            if ( scalar @extra == 2 ) {
                push @extra, {};
            } elsif (scalar @extra > 2 ) {
                die "Too many args when calling _list for all...";
            }
            $extra[-1] = { %{ $extra[-1] }, %$extra_filters };

            note "EXTRA args..... ", explain \@extra;
        }

        # note "*** All args: ", explain $all_args;
        # if ( $uri eq 'v2.0/ports' ) {
        #   # apply valid filters to the request itself
        #   note "== ~~ "x20;
        #   push @extra, { 'device_id', '42147502-68f1-41f8-a764-ada8dae81d65' };
        #   #die "====== BOOOM ====";
        # }

        @all = $self->client->all( $uri, @extra );  
    }
    
    note "** ALL: ", explain \@all;
    note "version: ", $self->version;
    note "version_prefix: ", $self->version_prefix;

    my @args = @$caller_args;

    # apply our filters to the raw results
    my $nargs = scalar @args;
    if ( $nargs && $nargs  % 2 == 0 ) {
        my %opts = @args;
        foreach my $filter ( sort keys %opts ) {
            my @keep;
            my $filter_isa = ref $opts{$filter} // '';
            foreach my $candidate ( @all ) {
                next unless ref $candidate;         
                if ( $filter_isa eq 'Regexp' ) {
                    # can use a regexp as a filter
                    next unless $candidate->{$filter} && $candidate->{$filter} =~ $opts{$filter};
                } else {
                    # otherwise do one 'eq' check
                    next unless $candidate->{$filter} && $candidate->{$filter} eq $opts{$filter};
                }

                push @keep, $candidate;
            }

            @all = @keep;
            # grep { ref $_ && defined $_->{$filter} && $_->{$filter} eq $opts{$filter} } @all;
        }
    }

    # avoid to return a list when possible  
    return $all[0] if scalar @all <= 1;
    
    # return a list
    return @all;
}

1;