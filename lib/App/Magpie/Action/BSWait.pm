use 5.012;
use strict;
use warnings;

package App::Magpie::Action::BSWait;
# ABSTRACT: bswait command implementation

use LWP::UserAgent;
use Moose;

with 'App::Magpie::Role::Logging';


=method run

    App::Magpie::Action::BSWait->new->run( $opts );

Check Mageia build-system and fetch the wait hint. Sleep according to
this hint, unless $opts->{nosleep} is true.

=cut

sub run {
    my ($self, $opts) = @_;
    $self->log( "checking bs wait hint" );

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->head('http://pkgsubmit.mageia.org/');
    $self->log_fatal( $response->status_line ) unless $response->is_success;

    my $sleep = $response->header( "x-bs-throttle" );
    $self->log( "bs recommends to sleep $sleep seconds" );

    if ( !$opts->{nosleep} && $sleep ) {
        $self->log_debug( "sleeping $sleep seconds" );
        sleep($sleep);
    }

    return $sleep;
}



1;
__END__

=head1 SYNOPSIS

    my $bswait = App::Magpie::Action::BSWait->new;
    $bswait->run;


=head1 DESCRIPTION

This module implements the C<bswait> action. It's in a module of its own
to be able to be C<require>-d without loading all other actions.

