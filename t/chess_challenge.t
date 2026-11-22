use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Plack::Test;
use HTTP::Request::Common;
use Academy::ChessChallenge;
use Web;

my $path = 'public/data/mate-in-three.json';
my $validator = Academy::ChessChallenge->new(catalog_path => $path);
open my $fh, '<', $path or die $!;
my $catalog = JSON::PP::decode_json(do { local $/; <$fh> });
close $fh;
for my $p (@{$catalog->{puzzles}}) {
    my @line = @{$p->{moves}}[$p->{setup_plies} .. $#{$p->{moves}}];
    ok($validator->verify({puzzleId => $p->{id}, line => \@line})->{ok},
        "$p->{id}: full legal reference line is checkmate");
}

my $id = 'mate-three-09tn6';
my @prefix = qw(d5f7 f8f7 e3e8 f7f8);
for my $finish (qw(f1f8 e8f8)) {
    test_psgi app => Web->to_app, client => sub {
        my $cb = shift;
        is($cb->(GET '/Step01')->code, 302, 'fresh visitor cannot access lessons');
        my $res = $cb->(POST '/api/chess/unlock', Content_Type => 'application/json',
            Content => JSON::PP::encode_json({puzzleId => $id, line => [@prefix, $finish]}));
        is($res->code, 200, "$finish is accepted without matching the reference line");
        ok(JSON::PP::decode_json($res->content)->{unlocked}, 'server confirms access');
        my $cookie = join('; ', map { (split /;/)[0] } $res->header('Set-Cookie'));
        is($cb->(GET '/Step01', Cookie => $cookie)->code, 200, 'session really opens lessons');
    };
}

my @invalid = (
    ['unknown puzzle', {puzzleId => 'untrusted', line => [@prefix, 'e8f8']}],
    ['illegal rook jump', {puzzleId => $id, line => [qw(d5f7 f8f7 e3e8 f7f8 f1g8)]}],
    ['legal move without mate', {puzzleId => $id, line => [@prefix, 'e8e7']}],
    ['wrong side moves', {puzzleId => $id, line => [qw(f8f7 d5f7 e3e8 f7f8 f1f8)]}],
    ['incomplete sequence', {puzzleId => $id, line => [@prefix]}],
    ['extra move', {puzzleId => $id, line => [@prefix, 'e8f8', 'g8f8']}],
    ['invalid coordinate', {puzzleId => $id, line => [@prefix, 'e8f8<script>']}],
    ['rook cannot promote', {puzzleId => $id, line => [@prefix, 'e8f8q']}],
    ['structured move', {puzzleId => $id, line => [@prefix, {from => 'e8', to => 'f8'}]}],
    ['forged browser result', {puzzleId => $id, checkmate => 1, fen => 'fake', line => [@prefix, 'e8e7']}],
    ['not an object', []],
);
for my $case (@invalid) {
    my ($label, $body) = @$case;
    test_psgi app => Web->to_app, client => sub {
        my $cb = shift;
        my $res = $cb->(POST '/api/chess/unlock', Content_Type => 'application/json',
            Content => JSON::PP::encode_json($body));
        is($res->code, 400, "$label rejected");
        my $cookie = join('; ', map { (split /;/)[0] } $res->header('Set-Cookie'));
        is($cb->(GET '/Step01', Cookie => $cookie)->code, 302, "$label cannot open lessons");
    };
}
done_testing;
