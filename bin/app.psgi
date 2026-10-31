#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Web;
my $app = Web->to_app;

# Opt in by configuring a private local SQLite file. Without it, preserve
# Academy's existing behavior (including Dancer2 session cookies).
if (defined($ENV{ACADEMY_VISITOR_DB}) && length($ENV{ACADEMY_VISITOR_DB})) {
    require Academy::VisitorMiddleware;
    $app = Academy::VisitorMiddleware->wrap(
        $app, db_path => $ENV{ACADEMY_VISITOR_DB}
    );
}
$app;
