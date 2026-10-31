package Academy::VisitorMiddleware;
use strict;
use warnings;
use DBI;
use Academy::VisitorCookie;

sub wrap {
    my ($class, $app, %options) = @_;
    die "PSGI app required\n" unless ref($app) eq 'CODE';
    die "Unsupported middleware option\n" if grep { $_ ne 'db_path' } keys %options;
    my $path = $options{db_path};
    die "Explicit on-disk SQLite path required\n"
        unless defined($path) && !ref($path) && length($path)
        && $path ne ':memory:' && $path !~ /\0/;

    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $path, '', '', {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
        sqlite_unicode => 1, sqlite_busy_timeout => 5000,
    }) or die "Cannot open visitor database\n";
    my $registry = Academy::VisitorCookie->new(dbh => $dbh);

    return sub {
        my ($env) = @_;
        my $cookie = $env->{HTTP_COOKIE} // '';
        my ($id) = $cookie =~ /(?:\A|;\s*)academy_visitor=([a-f0-9]{64})(?:;|\z)/;
        my $visitor = $registry->identify(cookie_id => $id);
        $env->{'academy.visitor'} = {
            visitor_id => $visitor->{visitor_id},
            created_at => $visitor->{created_at},
            last_seen_at => $visitor->{last_seen_at},
            expires_at => $visitor->{expires_at},
        };
        my $secure = ($env->{'psgi.url_scheme'} // '') eq 'https' ? 1 : 0;
        my $set_cookie = $registry->cookie_header(
            visitor_id => $visitor->{visitor_id}, secure => $secure
        );

        my $response = $app->($env);
        # PSGI delayed responders must be wrapped at their callback boundary.
        if (ref($response) eq 'CODE') {
            return sub {
                my ($responder) = @_;
                return $response->(sub {
                    my ($res) = @_;
                    _append_cookie($res, $set_cookie);
                    return $responder->($res);
                });
            };
        }
        _append_cookie($response, $set_cookie);
        return $response;
    };
}

sub _append_cookie {
    my ($response, $cookie) = @_;
    die "Unexpected PSGI response\n"
        unless ref($response) eq 'ARRAY'
        && ref($response->[1]) eq 'ARRAY';
    push @{$response->[1]}, 'Set-Cookie' => $cookie;
    return $response;
}

1;
