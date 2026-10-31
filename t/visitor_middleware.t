use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Academy::VisitorMiddleware;

my $dir = tempdir(CLEANUP => 1);
my $db = File::Spec->catfile($dir, 'visitors.sqlite');
my @seen;
my $app = Academy::VisitorMiddleware->wrap(sub {
    my ($env) = @_;
    push @seen, $env->{'academy.visitor'};
    return [200, ['Content-Type' => 'text/plain', 'Set-Cookie' => 'dancer.session=abc; Path=/'], ['OK']];
}, db_path => $db);
ok(-f $db, 'local SQLite database created');

my $first = $app->({ 'psgi.url_scheme' => 'http' });
is($first->[0], 200, 'request served');
my @set = _headers($first->[1], 'Set-Cookie');
is(scalar(@set), 2, 'existing Dancer session cookie preserved');
like($set[1], qr/\Aacademy_visitor=([a-f0-9]{64}); Path=\/; Max-Age=31536000; HttpOnly; SameSite=Lax\z/,
    'anonymous cookie added with safe attributes');
my ($id) = $set[1] =~ /academy_visitor=([a-f0-9]{64})/;
is($seen[0]{visitor_id}, $id, 'validated ID exposed to internal PSGI app');
my $return = $app->({
    'psgi.url_scheme' => 'https',
    HTTP_COOKIE => "other=1; academy_visitor=$id; other2=2",
});
my @return_set = _headers($return->[1], 'Set-Cookie');
like($return_set[1], qr/; Secure\z/, 'HTTPS gets Secure cookie');
is($seen[1]{visitor_id}, $id, 'returning browser recognized');
is($seen[1]{created_at}, $seen[0]{created_at}, 'original creation time preserved');
my $forged = $app->({
    'psgi.url_scheme' => 'https',
    HTTP_COOKIE => 'academy_visitor=' . ('f' x 64),
});
isnt($seen[2]{visitor_id}, 'f' x 64, 'unknown cookie rejected');
isnt($seen[2]{visitor_id}, $id, 'unknown cookie gets new visitor ID');

my $delayed = Academy::VisitorMiddleware->wrap(sub {
    return sub {
        my ($respond) = @_;
        $respond->([200, ['Content-Type' => 'text/plain'], ['OK']]);
    };
}, db_path => $db);
my $response_cb = $delayed->({ 'psgi.url_scheme' => 'https' });
is(ref($response_cb), 'CODE', 'delayed response preserved');
my $delayed_response;
$response_cb->(sub { $delayed_response = shift });
my @delayed_cookies = _headers($delayed_response->[1], 'Set-Cookie');
is(scalar(@delayed_cookies), 1, 'delayed response receives visitor cookie');

sub _headers {
    my ($headers, $name) = @_;
    my @values;
    for (my $i = 0; $i < @$headers; $i += 2) {
        push @values, $headers->[$i + 1] if lc($headers->[$i]) eq lc($name);
    }
    return @values;
}
done_testing();
