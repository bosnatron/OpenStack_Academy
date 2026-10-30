use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Web;

my $app = Web->to_app;
isa_ok($app, 'CODE', 'PSGI application');

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $home = $cb->(GET '/');
    is($home->code, 200, 'homepage available without login');
    like($home->content, qr/OpenStack Academy/, 'homepage has site title');
    for my $n (1 .. 9) {
        my $path = sprintf '/Step%02d', $n;
        my $res = $cb->(GET $path);
        is($res->code, 200, "$path available");
    }
};
done_testing;
