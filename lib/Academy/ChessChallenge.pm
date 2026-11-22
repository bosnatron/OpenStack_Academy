package Academy::ChessChallenge;
use strict;
use warnings;
use Chess::Rep 0.8;
use JSON::PP ();

# The catalog owns the starting position. Never accept a browser-supplied FEN
# or a browser's claim that a position is checkmate.
sub new {
    my ($class, %args) = @_;
    open my $fh, '<:raw', $args{catalog_path} or die "Cannot open chess catalog: $!";
    my $catalog = JSON::PP::decode_json(do { local $/; <$fh> });
    close $fh;
    die 'Unsupported chess catalog' unless ref($catalog) eq 'HASH'
        && ($catalog->{schema_version} // 0) == 2 && ref($catalog->{puzzles}) eq 'ARRAY';
    my %positions;
    for my $p (@{$catalog->{puzzles}}) {
        die 'Invalid chess puzzle' unless ref($p) eq 'HASH'
            && defined($p->{id}) && !ref($p->{id}) && $p->{id} =~ /\A[a-zA-Z0-9-]{1,80}\z/
            && defined($p->{setup_plies}) && !ref($p->{setup_plies})
            && $p->{setup_plies} =~ /\A[01]\z/ && ref($p->{moves}) eq 'ARRAY'
            && @{$p->{moves}} == $p->{setup_plies} + 5;
        die 'Duplicate chess puzzle' if exists $positions{$p->{id}};
        my $board = Chess::Rep->new($p->{fen});
        for my $i (0 .. $p->{setup_plies} - 1) {
            _move($board, $p->{moves}[$i]);
        }
        $positions{$p->{id}} = $board->get_fen;
        # Check the reference line on startup, but do not require visitors to
        # reproduce it. Its only purpose is guidance for the browser opponent.
        my $example = [@{$p->{moves}}[$p->{setup_plies} .. $#{$p->{moves}}]];
        die 'Invalid reference solution' unless _mate_after_three($board, $example);
    }
    die 'Empty chess catalog' unless keys %positions;
    return bless { positions => \%positions }, $class;
}

sub _move {
    my ($board, $move) = @_;
    die 'Invalid coordinate move' unless defined($move) && !ref($move)
        && $move =~ /\A[a-h][1-8][a-h][1-8][qrbn]?\z/;
    my ($piece) = $board->get_piece_at(substr($move, 0, 2));
    my $promotion = $piece && ($piece & 1) && substr($move, 3, 1) =~ /[18]/;
    # Chess::Rep's flexible notation accepts promotion suffixes even for
    # non-pawns. UCI input must neither invent nor omit a promotion.
    die 'Invalid promotion' if (length($move) == 5 ? 1 : 0) != ($promotion ? 1 : 0);
    # go_move checks against the current legal moves, including king safety.
    $board->go_move($move);
}

sub _mate_after_three {
    my ($board, $line) = @_;
    for my $move (@$line) {
        my $before = $board->status;
        return 0 if $before->{mate} || $before->{stalemate};
        _move($board, $move);
    }
    my $after = $board->status;
    return $after->{check} && $after->{mate} && !@{$after->{moves}} ? 1 : 0;
}

sub verify {
    my ($self, $data) = @_;
    return { ok => 0, error => 'Invalid challenge submission' }
        unless ref($data) eq 'HASH' && defined($data->{puzzleId}) && !ref($data->{puzzleId})
        && exists($self->{positions}{$data->{puzzleId}})
        && ref($data->{line}) eq 'ARRAY' && @{$data->{line}} == 5;
    my $ok = eval {
        my $board = Chess::Rep->new($self->{positions}{$data->{puzzleId}});
        _mate_after_three($board, $data->{line});
    };
    return $ok ? { ok => 1 }
        : { ok => 0, error => 'The moves must be legal and end in checkmate on move three' };
}

1;
