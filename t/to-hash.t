use v6;
use Test;
use Facter;

my $facter = Facter.new;
ok($facter, "Facter loaded");

my %facts = $facter.to_hash;

ok(%facts, 'Facter.to_hash call produces some result');

is(%facts<perl6os>, $*DISTRO, 'perl6os fact has the correct value');

done;

