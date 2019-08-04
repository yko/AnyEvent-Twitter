use warnings;
use strict;
use lib 't/lib';
use Test::More;

BEGIN {
    eval { require AnyEvent::HTTPD; 1 }
      // plan skip_all => 'AnyEvent::HTTPD required for this test';

    require AnyEvent::HTTPD::Util;
}

use AnyEvent::Twitter::MockAPI;
use AnyEvent::Twitter;
use JSON;

my $httpd = AnyEvent::Twitter::MockAPI->install_mock_httpd;

$httpd->reg_cb(
    '/1.1/parameters-form.json' => sub {
        my ($httpd, $req) = @_;
        $httpd->stop_request;

        my %vars   = $req->vars;
        my $params = AnyEvent::HTTPD::Util::parse_urlencoded($req->content);
        my $foo_value = $params->{foo}[0][0];

        $req->respond(
            [   200, 'Ok',
                {'Content-Type' => 'application/json'},
                encode_json({"endpoint" => "foo=$vars{foo}"})
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
    method => 'GET',
    api    => 'parameters-form',
    params => {foo => 'bar'},
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "foo=bar",
          "request GET response matches expectations";

        $cv->end;
    }
);

$cv->begin;
$ua->get(
    'parameters-form' => {foo => 'bar'},
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "foo=bar",
          "->get response matches expectations";

        $cv->end;
    }
);

$cv->begin;
$ua->request(
    method => 'POST',
    api    => 'parameters-form',
    params => {foo => 'bar'},
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "foo=bar",
          "POST request response matches expectations";

        $cv->end;
    }
);

$cv->begin;
$ua->post(
    'parameters-form' => {foo => 'bar'},
    sub {
        my ($header, $response, $reason, $error_response) = @_;

        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "foo=bar",
          "->post response matches expectations";

        $cv->end;
    }
);

AnyEvent::Twitter::MockAPI->start($cv);

done_testing;
