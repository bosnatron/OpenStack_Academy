use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
use DBI;
use Academy::VisitorMiddleware;

my $dir=tempdir(CLEANUP=>1);my $path="$dir/private/visitors.sqlite";
my $mask=umask;
my $app=Academy::VisitorMiddleware->wrap(sub {
    my ($env)=@_;
    die "Application failed\n" if ($env->{PATH_INFO}//'') eq '/failure';
    return [404,['Content-Type'=>'text/html'],['missing']] if $env->{PATH_INFO} eq '/missing';
    return [200,['Content-Type'=>'text/css'],['body{}']] if $env->{PATH_INFO} eq '/style.css';
    return sub {my ($respond)=@_;return $respond->([202,['Content-Type'=>'text/html; charset=utf-8'],['later']])}
        if $env->{PATH_INFO} eq '/delayed';
    return [200,['Content-Type'=>'text/html; charset=utf-8'],['ok']];
},db_path=>$path);
is(umask,$mask,'collector restores the caller umask');
is((stat($path))[2]&0777,0600,'new visitor database is private');
my $first=$app->({REQUEST_METHOD=>'GET',PATH_INFO=>'/',QUERY_STRING=>'password=secret',HTTP_AUTHORIZATION=>'Bearer secret','psgi.url_scheme'=>'http'});
my ($header)=grep {defined($_) && /\Aacademy_visitor=/} @{$first->[1]};
my ($id)=$header=~/academy_visitor=([a-f0-9]{64})/;
ok($id,'collector still issues the visitor cookie');
sub request {my ($method,$url)=@_;return $app->({REQUEST_METHOD=>$method,PATH_INFO=>$url,
    HTTP_COOKIE=>'academy_visitor='.$id,QUERY_STRING=>'private=yes','psgi.url_scheme'=>'http'})}
request('GET','/Step01?token=private');
request('GET','/style.css');request('POST','/api/chess/unlock');request('GET','/missing');
my $delayed=request('GET','/delayed');my $answer;$delayed->(sub {$answer=shift;return 'responder-result'});
is($answer->[0],202,'delayed responder remains intact');
eval {request('GET','/failure')};like($@,qr/Application failed/,'application exceptions are preserved');
my $db=DBI->connect('dbi:SQLite:dbname='.$path,'','',{RaiseError=>1,PrintError=>0});
my $rows=$db->selectall_arrayref('SELECT * FROM academy_visitor_activity ORDER BY id',{Slice=>{}});
is(scalar(@$rows),7,'all ordinary, delayed, and failed requests recorded once');
is_deeply([map {$_->{path}} @$rows],['/','/Step01','/style.css','/api/chess/unlock','/missing','/delayed','/failure'],'paths recorded without query strings');
is_deeply([map {$_->{is_page}} @$rows],[1,1,0,0,0,1,0],'only successful HTML GET responses count as page views');
is_deeply([map {$_->{status}} @$rows],[200,200,200,200,404,202,500],'actual response and failure statuses captured');
is(scalar(grep {$_->{browser_key} eq sha256_hex($id)} @$rows),7,'returning browser activity uses one stable hashed key');
ok(!grep({$_->{browser_key} eq $id} @$rows),'events do not store the bearer cookie');
ok(!grep({$_->{response_ready_ms}<0} @$rows),'header response timings are nonnegative');
my $columns=$db->selectall_arrayref('PRAGMA table_info(academy_visitor_activity)',{Slice=>{}});
ok(!grep({$_->{name}=~/cookie|authorization|body|query/i} @$columns),'request bodies and credentials have no activity fields');
my $text=join(' ',map {join(' ',values %$_)} @$rows);
unlike($text,qr/password|secret|private=yes|token=private/,'sensitive query and authorization data are absent');
my $before=$db->selectrow_array('SELECT COUNT(*) FROM academy_visitor_activity');
$db->do('DROP TABLE academy_visitor_activity');
my $warning='';my $response;
{local $SIG{__WARN__}=sub {$warning.=shift};$response=request('GET','/still-works')}
is($response->[0],200,'activity storage failure does not break the website response');
like($warning,qr/activity could not be recorded/,'storage failure is visible to the operator');
$db->disconnect;
done_testing;
