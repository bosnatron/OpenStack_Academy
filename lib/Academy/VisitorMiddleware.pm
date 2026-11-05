package Academy::VisitorMiddleware;
use strict;
use warnings;
use DBI;
use Academy::VisitorCookie;
use Academy::VisitorActivity;
use Time::HiRes ();
use File::Basename qw(dirname);
use File::Path qw(make_path);

sub wrap {
    my ($class, $app, %options) = @_;
    die "PSGI app required\n" unless ref($app) eq 'CODE';
    die "Unsupported middleware option\n" if grep { $_ ne 'db_path' } keys %options;
    my $path = $options{db_path};
    die "Explicit on-disk SQLite path required\n"
        unless defined($path) && !ref($path) && length($path)
        && $path ne ':memory:' && $path !~ /\0/;

    die "Visitor database must not be a symlink\n" if -l $path;
    my $parent = dirname($path);
    die "Visitor data directory must not be a symlink\n" if -l $parent;
    for my $file ($path, map { $path.$_ } qw(-wal -shm -journal)) {
        die "Visitor database must not use links\n" if -l $file || (-e $file && (stat($file))[3] != 1);
    }

    my $mask = umask 0077;
    my $dbh = eval {
        make_path($parent, { mode => 0700 }) unless -d $parent;
        DBI->connect('dbi:SQLite:dbname=' . $path, '', '', {
        RaiseError => 1, PrintError => 0, AutoCommit => 1,
        sqlite_unicode => 1, sqlite_busy_timeout => 5000,
    }) };
    my $error = $@; umask $mask;
    die($error || "Cannot open visitor database\n") unless $dbh;
    my $registry = Academy::VisitorCookie->new(dbh => $dbh);
    my $activity = Academy::VisitorActivity->new(dbh => $dbh);

    return sub {
        my ($env) = @_;
        my $started = Time::HiRes::time();
        my $at = time;
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

        my $recorded = 0;
        my $record = sub {
            my ($res) = @_;
            return if $recorded++;
            my $status = ref($res) eq 'ARRAY' ? $res->[0] : 500;
            my $type = '';
            if (ref($res) eq 'ARRAY' && ref($res->[1]) eq 'ARRAY') {
                for (my $i=0; $i<@{$res->[1]}; $i+=2) {
                    $type = $res->[1][$i+1] // '' if lc($res->[1][$i]) eq 'content-type';
                }
            }
            my $ms = int((Time::HiRes::time()-$started)*1000); $ms=0 if $ms<0;
            my $ok = eval { $activity->record(visitor_id=>$visitor->{visitor_id}, at=>$at,
                method=>$env->{REQUEST_METHOD}, path=>$env->{PATH_INFO}, status=>$status,
                response_ready_ms=>$ms, is_page=>(($env->{REQUEST_METHOD}//'') eq 'GET'
                    && $status>=200 && $status<300 && $type =~ m{\Atext/html(?:;|\z)}i) ? 1 : 0); 1 };
            warn "Academy visitor activity could not be recorded\n" unless $ok;
        };
        my $response = eval { $app->($env) };
        if (my $failure = $@) { $record->(); die $failure; }
        # PSGI delayed responders must be wrapped at their callback boundary.
        if (ref($response) eq 'CODE') {
            return sub {
                my ($responder) = @_;
                my $result = eval { $response->(sub {
                    my ($res) = @_;
                    _append_cookie($res, $set_cookie);
                    $record->($res);
                    return $responder->($res);
                }) };
                if (my $failure = $@) { $record->(); die $failure; }
                return $result;
            };
        }
        _append_cookie($response, $set_cookie);
        $record->($response);
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
