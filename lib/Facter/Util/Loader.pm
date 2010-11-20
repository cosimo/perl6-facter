# Load facts on demand

use v6;

class Facter::Util::Loader;

has $!loaded_all is rw = False;

# Load all resolutions for a single fact.
method load($fact) {

    # Now load from the search path
    my $shortname = $fact.Str.lc;
    self.load_env($shortname);

    # TODO: would be cool to also run the ".rb" facts
    my $filename = $shortname ~ ".pm";

    eval "require 'Facter/$filename'" or do {
        warn "Unable to load fact $shortname: $!";
        return;
    };

    return;

    for self.search_path -> $dir {
        # Load individual files
        my $file = join('/', $dir, $filename);

        self.load_file($file) if $file.IO ~~ :e;   # exists

        # And load any directories matching the name
        my $factdir = join('/', $dir, $shortname);
        self.load_dir($factdir) if $factdir.IO ~~ :d;
    }

}

# Load all facts from all directories.
method load_all () {
    return if defined $!loaded_all;

    self.load_env();

    for self.search_path -> $dir {

        next unless $dir.IO ~~ :d;

        for dir($dir) -> $file {
            my $path = join('/', $dir, $file);
            if $path.IO ~~ :d {
                self.load_dir($path);
            } elsif $file ~~ /\.pm$/ {
                self.load_file($path);
            }
        }
    }

    $!loaded_all = True;
}

# The list of directories we're going to search through for facts.
method search_path {

    my @result = map {"$_/Facter"}, @*INC;

    my $facter_lib = $*ENV<FACTERLIB>;
    if $facter_lib.defined {
        @result.push($facter_lib.split(":"));
    }

    # This allows others to register additional paths we should search.
    @result.push(Facter.new.search_path);

    return @result;
}

#private

method load_dir($dir) {

    return if $dir ~~ /\/\.+$/
        or $dir ~~ /\/util$/
        or $dir ~~ /\/lib$/;

    for dir($dir) -> $f {
        next unless $f ~~ /\.pm$/;
        self.load_file(join('/', $dir, $f));
    }

}

method load_file($file) {
    say "require '$file'";
    eval("require '$file'") or do {
        warn "Error loading fact $file: $!\n";
        return False;
    };
    return True;
}

# Load facts from the environment.  If no name is provided,
# all will be loaded.
method load_env($fact = "") {

    # TODO Iterate over %*ENV not possible?
    return;

    # Load from the environment, if possible
    for %*ENV.kv -> $name, $value {

        # Skip anything that doesn't match our regex.
        next unless $name ~~ m:i/^facter_?(\w+)$/;
        my $env_name = $0;

        # If a fact name was specified,
        # skip anything that doesn't match it.
        next if $fact and $env_name != $fact;

        Facter.add($env_name, $value);

        # Short-cut, if we are only looking for one value.
        last if $fact;
    }

}

