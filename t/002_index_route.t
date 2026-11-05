use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP ();
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
        is($res->code, 302, "$path requires completing the chess entrance challenge");
    }
    my $invalid=$cb->(POST '/api/chess/unlock',Content_Type=>'application/json',Content=>'{}');
    is($invalid->code,400,'invalid chess solution does not unlock lessons');
    my $unlock=$cb->(POST '/api/chess/unlock',Content_Type=>'application/json',
        Content=>JSON::PP::encode_json({puzzleId=>'queen-sacrifice-001',line=>[qw(a2c4 c3d2 c4c1 d2c1 c5b3)]}));
    is($unlock->code,200,'verified complete chess line unlocks lessons');
    my $cookie=join('; ',map {my ($part)=split /;/; $part} $unlock->header('Set-Cookie'));
    for my $n (1..9) {
        my $path=sprintf '/Step%02d',$n;
        is($cb->(GET $path,Cookie=>$cookie)->code,200,"$path available after the challenge");
    }
};
done_testing;
