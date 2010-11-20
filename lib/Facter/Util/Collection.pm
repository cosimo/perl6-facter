# Manage which facts exist and how we access them.  Largely just a wrapper
# around a hash of facts.
class Facter::Util::Collection;

#se Facter;
#se Facter::Util::Fact;
use Facter::Util::Loader;

# Private members
has %!facts is rw;


# Return a fact object by name.  If you use this, you still have to call
# 'value' on it to retrieve the actual value.
method get($name) {
    return $.value($name);
}

# Add a resolution mechanism for a named fact.  This does not distinguish
# between adding a new fact and adding a new way to resolve a fact.
method add($name, %options = (), Sub $block) {
    $name = $.canonize($name);

    my $fact = %!facts{$name};
    unless $fact {
        $fact = Facter::Util::Fact.new($name);
        %!facts{$name} = $fact;
    }

    # Set any fact-appropriate options.
    for %options.kv -> $opt, $value {
        my $method = $opt.Str;   # + "=" is a ruby fancyness
        if $fact.^can($method) {
            $fact.$method($value);
            %options{$opt}.delete;
        }
    }

    if $block {
        my $resolve = $fact.add($block);

        # Set any resolve-appropriate options
        for %options.kv -> $opt, $value {
            my $method = $opt.Str;  # again, + "="
            if $resolve.^can($method) {
                $resolve.$method($value);
                %options{$opt}.delete;
            }
        }
    }

    if %options.keys {
        die "Invalid facter option(s) " ~ %options.keys ==> map { $_.Str } ==> join(",");
    }

    return $fact;
}

# Iterate across all of the facts.
method each () {
    for %!facts.kv -> $name, $fact {
        my $value = $fact.value;
        if $value.defined {
            yield($name.Str, $value);
        }
    }
}

# Return a fact by name.
method fact($name) {
    $name = self.canonize($name);
    self.loader.load($name) unless %!facts{name};
    return %!facts{$name};
}

# Flush all cached values.
method flush {
    for %!facts.values -> $fact {
        $fact.flush if $fact;
    }
}

method initialize {
    %!facts = ();
}

# Return a list of all of the facts.
method list {
    return %!facts.keys
}

# Load all known facts.
method load_all {
    self.loader.load_all
}

# The thing that loads facts if we don't have them.
method loader {
    unless defined $!loader {
        $!loader = Facter::Util::Loader.new
    }
    return $!loader;
}

# Return a hash of all of our facts.
method to_hash {
    my %result;

    for %!facts.kv -> $name, $fact {
        my $value = $fact.value;
        if $value.defined {
            %result{$name.Str} = $value;
        }
    }

    return %result;
}

method value($name) {
    if my $fact = self.fact($name) {
        return $fact.value
    }
}

# Provide a consistent means of getting the exact same fact name
# every time.
method canonize($name) {
    $name.Str.lc;  # TODO: lookup to_sym ??
}

