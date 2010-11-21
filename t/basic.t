use v6;
use Test;
use Facter;

my $facter = Facter.new;
ok($facter, "Facter loaded");

my @search_dirs = $facter.search_path;
ok(@search_dirs.elems == 0, "Search path list is empty at startup");

my $coll = $facter.collection;
ok($coll, "Collection object is there");

my $test-fact = 'perl6os';

my $lsbdistname = $facter.fact($test-fact);
ok($lsbdistname, "fact '$test-fact' is loaded");

@search_dirs = $facter.search_path;
ok(@search_dirs.elems > 0, "Search path should be filled now");

diag("Collection object:" ~ $coll.perl);
diag("Search dirs:" ~ @search_dirs.perl);

done_testing;

