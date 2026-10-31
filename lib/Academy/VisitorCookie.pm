package Academy::VisitorCookie;
use strict;
use warnings;
use DBI;
use Digest::SHA qw(sha256_hex);
use MIME::Base64 ();
our $VERSION = '0.1.0';
my $YEAR = 365 * 24 * 60 * 60;

sub new {
    my ($class, %args) = @_;
    die "Only dbh and lifetime supported\n" if grep { $_ ne 'dbh' && $_ ne 'lifetime' } keys %args;
    my $dbh = $args{dbh};
    die "Database handle required\n" unless ref($dbh) && $dbh->can('do') && $dbh->can('selectrow_hashref');
    my $lifetime = defined($args{lifetime}) ? $args{lifetime} : $YEAR;
    die "Invalid lifetime\n" unless !ref($lifetime) && $lifetime =~ /\A[1-9][0-9]*\z/ && $lifetime <= 400 * 86400;
    $dbh->do(q{CREATE TABLE IF NOT EXISTS academy_visitor_cookies (
        visitor_id TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL,
        last_seen_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
    )});
    return bless { dbh => $dbh, lifetime => $lifetime }, $class;
}

sub _random_id {
    open my $fh, '<:raw', '/dev/urandom' or die "Secure random source unavailable\n";
    my $buf = '';
    while (length($buf) < 32) {
        my $got = read($fh, my $part, 32 - length($buf));
        die "Secure random source failed\n" unless defined($got) && $got > 0;
        $buf .= $part;
    }
    close $fh;
    return unpack('H*', $buf);
}

sub _timestamp {
    my ($at) = @_;
    $at = time unless defined $at;
    die "Invalid timestamp\n" unless !ref($at) && $at =~ /\A[0-9]{1,12}\z/;
    return 0 + $at;
}

sub identify {
    my ($self, %args) = @_;
    die "Unsupported argument\n" if grep { $_ ne 'cookie_id' && $_ ne 'at' } keys %args;
    my $at = _timestamp($args{at});
    my $candidate = $args{cookie_id};
    my $dbh = $self->{dbh};
    my $record;
    if (defined($candidate) && !ref($candidate) && $candidate =~ /\A[a-f0-9]{64}\z/) {
        $record = $dbh->selectrow_hashref(
            'SELECT visitor_id,created_at,expires_at FROM academy_visitor_cookies WHERE visitor_id=? AND expires_at>?',
            undef, $candidate, $at
        );
    }
    my $created = !$record;
    my $id = $created ? _random_id() : $record->{visitor_id};
    my $expires = $at + $self->{lifetime};
    if ($created) {
        $dbh->do(
            'INSERT INTO academy_visitor_cookies(visitor_id,created_at,last_seen_at,expires_at) VALUES (?,?,?,?)',
            undef, $id, $at, $at, $expires
        );
    } else {
        $dbh->do('UPDATE academy_visitor_cookies SET last_seen_at=?,expires_at=? WHERE visitor_id=?',
            undef, $at, $expires, $id);
    }
    return { visitor_id => $id, created => $created ? 1 : 0,
        created_at => $created ? $at : 0 + $record->{created_at},
        last_seen_at => $at, expires_at => $expires };
}

sub cookie_header {
    my ($self, %args) = @_;
    die "Unsupported cookie option\n" if grep { $_ ne 'visitor_id' && $_ ne 'secure' } keys %args;
    my $id = $args{visitor_id};
    die "Invalid visitor identifier\n" unless defined($id) && !ref($id) && $id =~ /\A[a-f0-9]{64}\z/;
    my $secure = $args{secure} ? '; Secure' : '';
    return 'academy_visitor=' . $id . '; Path=/; Max-Age=' . $self->{lifetime}
        . '; HttpOnly; SameSite=Lax' . $secure;
}

1;
