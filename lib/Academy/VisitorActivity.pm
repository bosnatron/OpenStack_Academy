package Academy::VisitorActivity;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);

our $VERSION = '0.1.0';

sub new {
    my ($class, %args) = @_;
    die "Only dbh supported\n" if grep { $_ ne 'dbh' } keys %args;
    my $dbh = $args{dbh};
    die "Database handle required\n" unless ref($dbh) && $dbh->can('do');
    $dbh->do(q{CREATE TABLE IF NOT EXISTS academy_visitor_activity (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        browser_key TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        method TEXT NOT NULL,
        path TEXT NOT NULL,
        status INTEGER NOT NULL,
        response_ready_ms INTEGER NOT NULL,
        is_page INTEGER NOT NULL
    )});
    $dbh->do('CREATE INDEX IF NOT EXISTS academy_activity_time ON academy_visitor_activity(occurred_at)');
    $dbh->do('CREATE INDEX IF NOT EXISTS academy_activity_browser_time ON academy_visitor_activity(browser_key,occurred_at)');
    return bless { dbh => $dbh }, $class;
}

sub record {
    my ($self, %a) = @_;
    die "Unknown activity field\n" if grep { !/\A(?:visitor_id|at|method|path|status|response_ready_ms|is_page)\z/ } keys %a;
    die "Invalid visitor ID\n" unless defined($a{visitor_id}) && !ref($a{visitor_id}) && $a{visitor_id} =~ /\A[a-f0-9]{64}\z/;
    die "Invalid activity time\n" unless defined($a{at}) && !ref($a{at}) && $a{at} =~ /\A[0-9]{1,12}\z/;
    die "Invalid response status\n" unless defined($a{status}) && !ref($a{status}) && $a{status} =~ /\A[1-5][0-9]{2}\z/;
    die "Invalid response timing\n" unless defined($a{response_ready_ms}) && !ref($a{response_ready_ms})
        && $a{response_ready_ms} =~ /\A[0-9]{1,12}\z/;
    my $method = $a{method} // 'UNKNOWN';
    $method = 'UNKNOWN' if ref($method) || $method !~ /\A[A-Z]{1,12}\z/;
    my $path = $a{path} // '/';
    die "Invalid request path\n" if ref($path);
    $path =~ s/[?#].*\z//s;
    $path =~ s/[\x00-\x1f\x7f]//g;
    $path = '/' unless length($path) && substr($path,0,1) eq '/';
    $path = substr($path,0,2048);
    $self->{dbh}->do(q{INSERT INTO academy_visitor_activity
        (browser_key,occurred_at,method,path,status,response_ready_ms,is_page) VALUES (?,?,?,?,?,?,?)},
        undef, sha256_hex($a{visitor_id}), 0+$a{at}, $method, $path, 0+$a{status},
        0+$a{response_ready_ms}, $a{is_page} ? 1 : 0);
    return 1;
}

1;
