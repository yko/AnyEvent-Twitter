package AnyEvent::Twitter::MockAPI;
use strict;
use warnings;
use AnyEvent::Twitter;
use AnyEvent::HTTPD;
use AE;

my $SINGLETON_MOCK;

sub install_mock_httpd {
    $SINGLETON_MOCK //= do {
      my $httpd = AnyEvent::HTTPD->new;
      $httpd->reg_cb (
        '/1.1' => sub {
              my ($httpd, $req) = @_;
              $req->respond(404, 'Not Found', {'Content-Type' => 'text/plain'}, 'Fail!');
        },
      );
      $httpd;
    };

    my $port = $SINGLETON_MOCK->port;
    %AnyEvent::Twitter::PATH = (
        site          => "http://localhost:$port/",
        request_token => "http://localhost:$port/oauth/request_token",
        authorize     => "http://localhost:$port/oauth/authorize",
        access_token  => "http://localhost:$port/oauth/access_token",
        authenticate  => "http://localhost:$port/oauth/authenticate",
    );
    %AnyEvent::Twitter::RESOURCE_URL_BASE = (
        '1.0' => "http://localhost:$port/1/%s.json",
        '1.1' => "http://localhost:$port/1.1/%s.json",
    );
    return $SINGLETON_MOCK;
}

sub start {
    my $class = shift;
    my $cv    = shift;
    my $w; $w = AE::timer 60, 0, sub {
        undef $w;
        print STDERR "Tests ran for more than 60 seconds. Unhandled exception in a callback?\n";
        exit 1;
    };
    $cv->wait;
}

1;

=head1 NAME

AnyEvent::Twitter::MockAPI - simple mocking of Twitter API

=head1 SYNOPSIS

    use AnyEvent::Twitter::MockAPI;

    my $httpd = AnyEvent::Twitter::MockAPI->install_mock_httpd;

    $httpd->reg_cb(
        '/1.1/test.json' => sub {
            my ($httpd, $req) = @_;

            $req->respond(
                [   200, 'Ok',
                    {'Content-Type' => 'application/json'},
                    '{"endpoint": "It works!"}'
                ]
            );
        }
    );

=head1 DESCRIPTION

L<AnyEvent::Twitter::MockAPI> is based on L<AnyEvent::HTTPD>
and is meant to simplify mocking of Twitter API for testing purposes.
It is used together with L<Test::More> to test L<AnyEvent::Twitter>.

  $ prove -l -v t/01_basic-requests.t

=head1 METHODS

L<AnyEvent::Twitter::MockAPI> implements a single method, that finds an empty port
and returns L<AnyEvent::HTTPD> instance configured to listen on it.

=head2 install_mock_httpd

  my $httpd = AnyEvent::Twitter::MockAPI->install_mock_httpd;

This method overrides L<AnyEvent::Twitter>'s definition of paths to Twitter API paths,
pointing all further calls to newly created MockAPI server. Unless this behavior is desired,
this method should be used only in tests.

Further endpoints configuration could be done with reg_cb calls,
according to L<AnyEvent::HTTPD> documentation.

=head1 SEE ALSO

L<Test::More>, L<AnyEvent::HTTPD>.

=cut
