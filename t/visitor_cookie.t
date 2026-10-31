use strict;
use warnings;
use Test::More;
use DBI;
use Academy::VisitorCookie;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
my $cookies = Academy::VisitorCookie->new(dbh => $dbh, lifetime => 100);
isa_ok($cookies, 'Academy::VisitorCookie');
my $first = $cookies->identify(at => 1000);
like($first->{visitor_id}, qr/\A[a-f0-9]{64}\z/, 'new visitor gets cryptographically random 256-bit ID');
is($first->{created}, 1, 'new record created');
is($first->{expires_at}, 1100, 'expiry stored');
my $return = $cookies->identify(cookie_id => $first->{visitor_id}, at => 1050);
is($return->{visitor_id}, $first->{visitor_id}, 'returning browser keeps identity');
is($return->{created}, 0, 'existing visitor reused');
is($return->{created_at}, 1000, 'original creation time retained');
is($return->{expires_at}, 1150, 'rolling expiry renewed');
my $invalid = $cookies->identify(cookie_id => 'f' x 64, at => 1060);
isnt($invalid->{visitor_id}, 'f' x 64, 'unknown cookie is not trusted');
my $expired = $cookies->identify(cookie_id => $first->{visitor_id}, at => 1151);
isnt($expired->{visitor_id}, $first->{visitor_id}, 'expired cookie not reused');
my $header = $cookies->cookie_header(visitor_id => $first->{visitor_id}, secure => 1);
like($header, qr/\Aacademy_visitor=[a-f0-9]{64}; Path=\/; Max-Age=100; HttpOnly; SameSite=Lax; Secure\z/, 'safe cookie flags');
my $local = $cookies->cookie_header(visitor_id => $first->{visitor_id}, secure => 0);
unlike($local, qr/; Secure/, 'local HTTP development supported');
eval { $cookies->cookie_header(visitor_id => 'bad') };
like($@, qr/Invalid visitor identifier/, 'invalid identifier rejected');
eval { Academy::VisitorCookie->new(dbh => $dbh, lifetime => 0) };
like($@, qr/Invalid lifetime/, 'invalid lifetime rejected');
done_testing();
