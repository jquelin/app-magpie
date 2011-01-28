use 5.012;
use strict;
use warnings;

package App::Magpie::App::Command::bswait;
# ABSTRACT: pause according to build-system recommendations

use LWP::UserAgent;

use App::Magpie::App -command;


# -- public methods

sub description {
"Pauses according to the recommendation of Mageia build-system.
Build-system provides some recommendation on how much time to pause
between 2 packages submission to not overload it - this is known as
throttling."
}

sub opt_spec {
    my $self = shift;
    return (
        [],
        [ 'display|d=s' => "text to display with --verbose" ],
        [ 'nosleep|n!'  => "don't sleep" ],
        [ 'verbose|v!'  => "display time to wait" ],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $opts->{display} //= "sleeping %d seconds\n";
    $opts->{nosleep} //= 0;
    $opts->{verbose} //= 0;
    $opts->{display} =~ s/\\n/\n/g;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;

    my $response = $ua->head('http://pkgsubmit.mageia.org/');
    die $response->status_line unless $response->is_success;

    my $sleep = $response->header( "x-bs-throttle" );

    printf($opts->{display}, $sleep) if $opts->{verbose};
    sleep($sleep)                    unless $opts->{sleep};
}

1;
__END__


=head1 DESCRIPTION

This command pauses according to the recommendation of Mageia
build-system. Indeed, instead of pushing all your packages to be
rebuilt, it's better to throttle them one at a time. Build-system
provides some recommendation on how much to pause between 2 packages -
and this command uses this hint to pause accordingly.
