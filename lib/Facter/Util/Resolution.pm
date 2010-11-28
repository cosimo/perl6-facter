=begin pod

=head1 NAME

Facter::Util::Resolution

=head1 DESCRIPTION

An actual fact resolution mechanism.  These are largely just chunks of
code, with optional confinements restricting the mechanisms to only working on
specific systems.  Note that the confinements are always ANDed, so any
confinements specified must all be true for the resolution to be
suitable.

=end pod

class Facter::Util::Resolution;

use Facter::Util::Confine;

#require 'timeout'
#require 'rbconfig'

has $.code is rw;
has $.interpreter is rw;
has $.name is rw;
has $.value is rw;
has $.timeout is rw;
has @.confines is rw;

our $WINDOWS = $*OS ~~ m:i/mswin|win32|dos|mingw|cygwin/;
our $INTERPRETER = $WINDOWS ?? 'cmd.exe' :: '/bin/sh'
our $HAVE_WHICH;

method have_which {
    if ! $HAVE_WHICH.defined {
        if Facter.value('kernel') == 'windows' {
            $HAVE_WHICH = False
        } else {
            $HAVE_WHICH = run('which which >/dev/null 2>&1') == 0;
        }
    }
    return $HAVE_WHICH;
}

# Execute a program and return the output of that program.
#
# Returns nil if the program can't be found, or if there is a problem
# executing the code.
#
method exec($code, $interpreter = $INTERPRETER) {

    unless $interpreter == $INTERPRETER {
        die "invalid interpreter";
    }

    # Try to guess whether the specified code can be executed by looking at the
    # first word. If it cannot be found on the PATH defer on resolving the fact
    # by returning nil.
    # This only fails on shell built-ins, most of which are masked by stuff in 
    # /bin or of dubious value anyways. In the worst case, "sh -c 'builtin'" can
    # be used to work around this limitation
    #
    # Windows' %x{} throws Errno::ENOENT when the command is not found, so we 
    # can skip the check there. This is good, since builtins cannot be found 
    # elsewhere.
    if $HAVE_WHICH and !$WINDOWS {
        my $path = Mu;
        my $binary = $.code.split.[0];
        if $.code ~~ /^\// {
            $path = $binary
        } else {
            $path = qx{which '$binary' 2>/dev/null}.chomp;
            # we don't have the binary necessary
            return if $path eq "" or $path.match(/Command not found\./);
        }

        return unless $path.IO ~~ :e;
    }

    my $out;

    try {
        $out = qx{$code}.chomp;
    } CATCH {
        warn "Command failed: $!";
        return;
    }

    if $out == "" {
        return
    }

    return $out;
}

# Add a new confine to the resolution mechanism.
method confine(%confines) {
    for %confines.kv -> $fact, $values {
        @.confines.push(Facter::Util::Confine.new($fact, $values);
    }
}

# Create a new resolution mechanism.
method initialize($name) {
    $.name = $name;
    @.confines = ();
    $.value = Mu;
    $.timeout = 0;
    return;
}

# Return the number of confines.
method length {
    @.confines.elems;
}

# We need this as a getter for 'timeout', because some versions
# of ruby seem to already have a 'timeout' method and we can't
# seem to override the instance methods, somehow.
method limit {
    $.timeout
}

# Set our code for returning a value.
method setcode($string = Mu, $interp = Mu, Sub $block)
    if $string {
        $.code = $string;
        $.interpreter = $interp || $INTERPRETER;
    } elsif $block {
        $.code = $block
    } else {
        die "You must pass either code or a block"
    }
}

# Is this resolution mechanism suitable on the system in question?
method suitable
    unless defined $.suitable {
        $.suitable = ! any(@confines, False);
    }
    return $.suitable;
}

method Str {
    return self.value()
}

# How we get a value for our resolution mechanism.
method value {

    if ! $.code and ! $.interpreter {
        return;
    }

    my $result;
    my $starttime = time;

=begin ruby
    begin
        Timeout.timeout(limit) do
            if @code.is_a?(Proc)
                result = @code.call()
            else
                result = Facter::Util::Resolution.exec(@code,@interpreter)
            }
        }
    rescue Timeout::Error => detail
        warn "Timed out seeking value for %s" % self.name

        # This call avoids zombies -- basically, create a thread that will
        # dezombify all of the child processes that we're ignoring because
        # of the timeout.
        Thread.new { Process.waitall }
        return nil
    rescue => details
        warn "Could not retrieve %s: %s" % [self.name, details]
        return nil
    }
=end ruby

    try {
        if "Sub()" eq $.code.WHAT {
            $result = $.code();
        } else {
            $result = Facter::Util::Resolution.exec($.code, $.interpreter);
        }
    }
    CATCH {
        warn "Could not retrieve $.name: $!";
        return
    }

    my $finishtime = time;
    my $ms = ($finishtime - $starttime) * 1000;
    Facter.show_time("$.name: $ms ms");

    return if $result eq "";
    return $result;
}

