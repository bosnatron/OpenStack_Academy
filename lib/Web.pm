package Web;
use strict;
use warnings;
use Dancer2;

# Public educational content; no WordPress or database connection required.
get '/' => sub { template 'index' };

for my $number (1 .. 9) {
    my $name = sprintf 'Step%02d', $number;
    get "/$name" => sub { template $name };
}

# Keep old form-based lesson links functional during migration.
post '/' => sub { redirect '/Step01' };
for my $number (2 .. 9) {
    my $name = sprintf 'Step%02d', $number;
    post "/$name" => sub { redirect "/$name" };
}

# Authentication was removed: hardcoded public credentials are unsafe.
get '/login'  => sub { redirect '/' };
get '/logout' => sub { redirect '/' };

dance;
1;
