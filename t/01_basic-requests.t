use strict;
use warnings;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require AnyEvent::HTTPD; 1 }
      // plan skip_all => 'AnyEvent::HTTPD required for this test';
}

use AnyEvent::Twitter::MockAPI;
use AnyEvent::Twitter;
use JSON;

my $httpd = AnyEvent::Twitter::MockAPI->install_mock_httpd;
$httpd->reg_cb(
    '/1.1/get-endpoint.json' => sub {
        my ($httpd, $req) = @_;

        $req->respond(
            [   200, 'Ok',
                {'Content-Type' => 'application/json'},
                '{"endpoint": "test get endpoint"}'
            ]
        );

    },
    '/1.1/post-endpoint.json' => sub {
        my ($httpd, $req) = @_;

        $req->respond(
            [   200, 'Ok',
                {'Content-Type' => 'application/json'},
                '{"endpoint": "test post endpoint"}'
            ]
        );

    },
);

my $cv = AE::cv;
my $ua = AnyEvent::Twitter->new(
    consumer_key        => 'consumer_key',
    consumer_secret     => 'consumer_secret',
    access_token        => 'access_token',
    access_token_secret => 'access_token_secret',
);

$cv->begin;
$ua->get(
    'get-endpoint',
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "test get endpoint",
          "->get request response matches expectations";

        $cv->end;
    }
);

$ua->request(
    method => 'GET',
    api    => 'get-endpoint',
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "test get endpoint",
          "GET request matches expectations";

        $cv->end;
    }
);

$cv->begin;
$ua->post(
    'post-endpoint',
    {},
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "test post endpoint",
          "->post request response matches expectations";

        $cv->end;
    }
);

$ua->request(
    method => 'POST',
    api    => 'post-endpoint',
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "test post endpoint",
          "POST request response matches expectations";

        $cv->end;
    }
);

AnyEvent::Twitter::MockAPI->start($cv);

done_testing;
