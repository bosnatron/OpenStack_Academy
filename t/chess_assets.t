use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
use JSON::PP ();
use Plack::Test;
use HTTP::Request::Common;
use Web;

sub read_bytes {
    open my $fh, '<:raw', $_[0] or die "$!";
    local $/;
    return <$fh>;
}
my $manifest = JSON::PP::decode_json(read_bytes('public/vendor/chess-assets.json'));
is($manifest->{chessground}{repository}, 'https://github.com/bosnatron/chessground',
    'Chessground comes from the owner fork');
test_psgi app => Web->to_app, client => sub {
    my $cb = shift;
    for my $file (sort keys %{$manifest->{sha256}}) {
        my $expected = read_bytes("public/vendor/$file");
        is(sha256_hex($expected), $manifest->{sha256}{$file}, "$file matches provenance hash");
        my $res = $cb->(GET "/vendor/$file");
        is($res->code, 200, "$file is available without a CDN");
        is(sha256_hex($res->content), $manifest->{sha256}{$file}, "$file served without alteration");
    }
    my $home = $cb->(GET '/')->content;
    unlike($home, qr{(?:src|href)="https?://(?:esm\.sh|cdn\.jsdelivr\.net)},
        'entrance does not load resources from the previous CDNs');
    like($home, qr{src="/js/academy-chess-entry\.js\?[^" ]+" defer},
        'independent welcome controller loads as a classic deferred script');
};
done_testing;
