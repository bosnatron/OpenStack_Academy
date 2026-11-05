use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Plack::Test;
use HTTP::Request::Common;
use DBI;

my $dir=tempdir(CLEANUP=>1);local $ENV{ACADEMY_VISITOR_DB}="$dir/data_local/academy-visitors.sqlite";
my $app=do './bin/app.psgi';die($@||$!) unless ref($app) eq 'CODE';
test_psgi app=>$app,client=>sub {
    my ($cb)=@_;
    my $home=$cb->(GET '/');is($home->code,200,'actual PSGI entrypoint serves the homepage');
    my ($cookie)=grep {/\Aacademy_visitor=/} $home->header('Set-Cookie');
    ok($cookie,'actual website response includes the Academy visitor cookie');
    ($cookie)=split /;/,$cookie;
    is($cb->(GET '/css/style.css',Cookie=>$cookie)->code,200,'static activity is served through the collector');
    is($cb->(POST '/api/chess/unlock',Cookie=>$cookie,Content_Type=>'application/json',Content=>'{}')->code,400,
        'failed entrance action keeps its real status');
};
my $db=DBI->connect('dbi:SQLite:dbname='.$ENV{ACADEMY_VISITOR_DB},'','',{RaiseError=>1,PrintError=>0});
is($db->selectrow_array('SELECT COUNT(*) FROM academy_visitor_cookies'),1,'actual returning requests stay linked to one browser');
my $rows=$db->selectall_arrayref('SELECT path,status,is_page FROM academy_visitor_activity ORDER BY id',{Slice=>{}});
is_deeply($rows,[{path=>'/',status=>200,is_page=>1},{path=>'/css/style.css',status=>200,is_page=>0},
    {path=>'/api/chess/unlock',status=>400,is_page=>0}],'production entrypoint records HTML, assets and failed actions correctly');
$db->disconnect;
done_testing;
