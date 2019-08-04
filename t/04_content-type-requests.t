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
    '/1.1/test-content-type.json' => sub {
        my ($httpd, $req) = @_;
        $httpd->stop_request;

        if ($req->headers->{'content-type'} ne 'application/json') {
            return $req->respond(
                [   400, 'Bad request',
                    {'Content-Type' => 'text/plain'},
                    'Accepting only Content-Type: application/json'
                ]
            );
        }

        $req->respond(
            [   200, 'Ok',
                {'Content-Type' => 'application/json'},
                '{ "endpoint": "test content-type:json endpoint"}'
            ]
        );
    }
);

my $cv = AE::cv;
my $ua = AnyEvent::Twitter->new(
    consumer_key        => 'consumer_key',
    consumer_secret     => 'consumer_secret',
    access_token        => 'access_token',
    access_token_secret => 'access_token_secret',
);

$cv->begin;
$ua->request(
    method       => 'POST',
    content_type => 'application/json',
    api          => 'test-content-type',
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "test content-type:json endpoint",
          "json endpoint response matches expectations";

        $cv->end;
    }
);

# content-type overwrite is only possible through ->post request

AnyEvent::Twitter::MockAPI->start($cv);

done_testing;
