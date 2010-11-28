class Facter::Util::Fact;

use Facter::Util::Resolution;

our $TIMEOUT = 5;

has $!value is rw;
has $!suitable is rw;

has $.name is rw;
has $.ldapname is rw;
has @.resolves is rw;
has $!searching is rw;

# Create a new fact, with no resolution mechanisms.
method initialize($name, %options = ()) {
    $.name = $name.Str.lc;   # XXX .intern ?

    if %options<ldapname>.exists {
        $.ldapname = %options<ldapname>;
    }

    $.ldapname //= $.name.Str;

    @.resolves = ();
    $!searching = false;
    $!value = Mu;
}

# Add a new resolution mechanism.  This requires a block, which will then
# be evaluated in the context of the new mechanism.
method add($block) {

    #raise ArgumentError, "You must pass a block to Fact<instance>.add" unless block_given?
    if ! $block {
        die "You must pass a block to Fact<instance>.add";
    }

    Facter.debug("Fact.add($.name, $block)");
    my $resolve = Facter::Util::Resolution.new(name => $.name);

    # ruby: resolve.instance_eval(block);
    $block($resolve);

    @.resolves.push($resolve);

    # Immediately sort the resolutions, so that we always have
    # a sorted list for looking up values.
    #  We always want to look them up in the order of number of
    # confines, so the most restricted resolution always wins.
    @.resolves = sort { $^b.elems <=> $^a.elems }, @.resolves;

    return $resolve;
}

# Flush any cached values.
method flush {
    $!value =
    $!suitable = Mu;
}

# Return the value for a given fact.  Searches through all of the mechanisms
# and returns either the first value or nil.
method value {
    return $!value if $!value;

    if @.resolves.elems == 0 {
        Facter.debug("No resolves for $!name");
        return;
    }

    self.searching(sub {
        $!value = Mu;

        my $foundsuits = False;

        while @.resolves {
            my $resolve = @.resolves.shift;
            next unless $resolve.suitable;
            $foundsuits = True;
            my $candidate_value = $resolve.value;
            if $candidate_value.defined and $candidate_value != "" {
                return $candidate_value;
            }
        }

        unless $foundsuits {
            Facter.debug("Found no suitable resolves of "
                ~ @!resolves.elems ~ " for " ~ $!name
            );
        }

    });

    if ! $!value.defined {
        Facter.debug("value for $!name is still undef");
        return;
    } else {
        return $!value
    }
}

# Are we in the midst of a search?
method are-we-searching {
    $!searching
}

# Lock our searching process, so we never ge stuck in recursion.
method searching (Sub $block) {

    if self.are-we-searching {
        Facter.debug("Caught recursion on $!name");

        # return a cached value if we've got it
        if $!value {
            return $!value
        } else {
            return
        }
    }

    # If we've gotten this far, we're not already searching, so go ahead and do so.
    $!searching = True;

    gather {
        take $block.();
        $!searching = False;
    };

    #begin
    #    yield
    #ensure
    #    @searching = false
    #end;

}

