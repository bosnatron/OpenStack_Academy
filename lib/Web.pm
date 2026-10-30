package Web;
use strict;
use warnings;
use Dancer2;
use JSON::PP qw(decode_json encode_json);

# First challenge: require the complete known legal checkmate line.
# This is an entrance challenge, not an anti-cheat chess engine.
my @solution = qw(a2c4 c3d2 c4c1 d2c1 c5b3);

get '/' => sub {
    template 'index', { unlocked => session('academy_unlocked') ? 1 : 0 };
};

post '/api/chess/unlock' => sub {
    content_type 'application/json';
    my $data = eval { decode_json(request->body // '') };
    if ($@ || ref($data) ne 'HASH' || ($data->{puzzleId} // '') ne 'queen-sacrifice-001'
        || ref($data->{line}) ne 'ARRAY' || @{$data->{line}} != @solution) {
        status 400;
        return encode_json({ ok => JSON::PP::false, error => 'Invalid challenge submission' });
    }
    for my $i (0 .. $#solution) {
        if (!defined $data->{line}[$i] || ref($data->{line}[$i])
            || $data->{line}[$i] ne $solution[$i]) {
            status 400;
            return encode_json({ ok => JSON::PP::false, error => 'Incorrect solution' });
        }
    }
    session academy_unlocked => 1;
    return encode_json({ ok => JSON::PP::true, unlocked => JSON::PP::true });
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

get '/login'  => sub { redirect '/' };
get '/logout' => sub { redirect '/' };

dance;
1;
