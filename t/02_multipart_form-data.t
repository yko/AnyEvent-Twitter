use strict;
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
    '/1.1/media-endpoint.json' => sub {
        my ($httpd, $req) = @_;
        $httpd->stop_request;

        if ($req->headers->{'content-type'} !~ m#^multipart/form-data;#) {
            return $req->respond(
                [   400, 'Bad request',
                    {'Content-Type' => 'text/plain'},
                    "Content-Type should be application/json"
                ]
            );
        }

        my %params = $req->vars;
        if ($params{'media[]'} =~ /\bcat\b/i) {
            return $req->respond(
                [   200, 'Ok',
                    {'Content-Type' => 'application/json'},
                    encode_json({endpoint => "Your cat looks good!"})
                ]
            );
        }
        else {
            return $req->respond(
                [   404,
                    'Cat not found',
                    {'Content-Type' => 'application/json'},
                    encode_json({endpoint => "I don't see a cat! :("})
                ]
            );
        }
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
$ua->post(
    'media-endpoint',
    [   'status'  => '桜',
        'media[]' => [undef, 'cat.jpg', Content => 'FF D8 Imaginary cat'],
    ],
    sub {
        my ($header, $response, $reason, $error_response) = @_;
        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "Your cat looks good!",
          "multipart ->post request response matches expectations";
        $cv->end;
    }
);

$cv->begin;
$ua->request(
    method => 'POST',
    api => 'media-endpoint',
    params => [   'status'  => '桜',
        'media[]' => [undef, 'cat.jpg', Content => 'FF D8 Imaginary cat'],
    ],
    sub {
        my ($header, $response, $reason, $error_response) = @_;
        is $header->{Status}, "200", "test request status 200 - Ok";
        is $response->{endpoint}, "Your cat looks good!",
          "multipart POST request response matches expectations";
        $cv->end;
    }
);

AnyEvent::Twitter::MockAPI->start($cv);

done_testing;
