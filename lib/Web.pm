package Web;
use strict;
use warnings;
use Dancer2;
use JSON::PP ();
our $VERSION = '0.2.0';

# First challenge: require the complete known legal checkmate line.
# This is an entrance challenge, not an anti-cheat chess engine.
my %solutions = (
    'queen-sacrifice-001' => [qw(a2c4 c3d2 c4c1 d2c1 c5b3)],
    'mate-three-001wr' => [qw(b4a5 a6b7 c4d6 b7b8 a5d8)],
    'mate-three-004kb' => [qw(f6f2 f1f2 e8e1 f2f1 e1f1)],
    'mate-three-005wy' => [qw(c6b4 c3b4 b8c8 d2c4 c8c4)],
    'mate-three-09tn6' => [qw(d5f7 f8f7 e3e8 f7f8 f1f8)],
    'mate-three-09usi' => [qw(f5e7 f8e7 e4h7 g8f8 h7h8)],
    'mate-three-09vao' => [qw(h7g6 h8g8 h6h7 g8f8 h7f7)],
    'mate-three-0a3ai' => [qw(g2g4 g1g4 h3g4 h5h4 b6h6)],
);

get '/' => sub {
    template 'index', { unlocked => session('academy_unlocked') ? 1 : 0 };
};

post '/api/chess/unlock' => sub {
    content_type 'application/json';
    my $data = eval { JSON::PP::decode_json(request->body // '') };
    my $solution = ref($data) eq 'HASH' ? $solutions{$data->{puzzleId} // ''} : undef;
    if ($@ || ref($data) ne 'HASH' || !$solution
        || ref($data->{line}) ne 'ARRAY' || @{$data->{line}} != @$solution) {
        status 400;
        return JSON::PP::encode_json({ ok => JSON::PP::false, error => 'Invalid challenge submission' });
    }
    for my $i (0 .. $#$solution) {
        if (!defined $data->{line}[$i] || ref($data->{line}[$i])
            || $data->{line}[$i] ne $solution->[$i]) {
            status 400;
            return JSON::PP::encode_json({ ok => JSON::PP::false, error => 'Incorrect solution' });
        }
    }
    session academy_unlocked => 1;
    return JSON::PP::encode_json({ ok => JSON::PP::true, unlocked => JSON::PP::true });
};

for my $number (1 .. 9) {
    my $name = sprintf 'Step%02d', $number;
    get "/$name" => sub {
        return redirect '/' unless session('academy_unlocked');
        return template $name;
    };
}

# Preserve legacy form links, but enforce the same gate on destination routes.
post '/' => sub { redirect(session('academy_unlocked') ? '/Step01' : '/') };
for my $number (2 .. 9) {
    my $name = sprintf 'Step%02d', $number;
    post "/$name" => sub { redirect(session('academy_unlocked') ? "/$name" : '/') };
}


# Bright Vale: local-only workspace. The BV transport remains disconnected
# until its actual Perl API contract and permissions have been verified.
get '/bv' => sub {
    return redirect '/' unless session('academy_unlocked');
    response_header 'Cache-Control' => 'no-store';
    template 'bv';
};

get '/api/bv/status' => sub {
    content_type 'application/json';
    response_header 'Cache-Control' => 'no-store';
    return JSON::PP::encode_json({
        connected => JSON::PP::false,
        mode => 'local',
        reason => 'BV local service is not configured',
    });
};

post '/api/bv/message' => sub {
    content_type 'application/json';
    response_header 'Cache-Control' => 'no-store';
    unless (session('academy_unlocked')) {
        status 403;
        return JSON::PP::encode_json({ ok => JSON::PP::false, error => 'Academy access required' });
    }
    status 503;
    return JSON::PP::encode_json({ ok => JSON::PP::false, error => 'BV local service is not connected yet' });
};

get '/login'  => sub { redirect '/' };
get '/logout' => sub { redirect '/' };

1;
