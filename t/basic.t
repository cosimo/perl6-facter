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

my $fact = $facter.fact($test-fact);
ok($fact, "test fact is loaded");
ok($fact.^can("value"), "fact object has a value() method");

my $lsbdistname = $facter.fact($test-fact).Str;
ok($lsbdistname, "fact '$test-fact' is loaded");
is($lsbdistname, $*OS, "test fact has correct value");

my $same-value = $facter.fact($test-fact).value;
is($lsbdistname, $same-value, "fact.value and fact.Str should yield the same result");

# Unused for now...
#@search_dirs = $facter.search_path;
#ok(@search_dirs.elems > 0, "Search path should be filled now");

diag("Collection object:" ~ $coll.perl);
diag("Search dirs:" ~ @search_dirs.perl);

done_testing;

