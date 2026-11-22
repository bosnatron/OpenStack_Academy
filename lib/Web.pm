package Web;
use strict;
use warnings;
use Dancer2;
use JSON::PP ();
use Academy::ChessChallenge;
our $VERSION = '0.2.0';

my $challenge = Academy::ChessChallenge->new(
    catalog_path => path(config->{appdir}, 'public', 'data', 'mate-in-three.json'),
);

get '/' => sub {
    my $unlocked = session('academy_unlocked') ? 1 : 0;
    template 'index', { unlocked => $unlocked,
        next_page => $unlocked ? '/Step01' : undef };
};

post '/api/chess/unlock' => sub {
    content_type 'application/json';
    my $body = request->body // '';
    my $data = length($body) <= 4096 ? eval { JSON::PP::decode_json($body) } : undef;
    my $result = $challenge->verify($data);
    unless ($result->{ok}) {
        status 400;
        return JSON::PP::encode_json({ ok => JSON::PP::false, error => $result->{error} });
    }
    session academy_unlocked => 1;
    return JSON::PP::encode_json({ ok => JSON::PP::true, unlocked => JSON::PP::true });
};

for my $number (1 .. 9) {
    my $name = sprintf 'Step%02d', $number;
    get "/$name" => sub {
        return redirect '/' unless session('academy_unlocked');
        return template $name, {
            previous_page => $number == 1 ? '/' : sprintf('/Step%02d', $number - 1),
            next_page => $number == 9 ? '/' : sprintf('/Step%02d', $number + 1),
            last_lesson => $number == 9 ? 1 : 0,
        };
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

1;
