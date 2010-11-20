#
# a Perl 6 port of ruby facter
#
# http://github.com/puppetlabs/facter/
#

#--
# Copyright 2006 Luke Kanies <luke@madstop.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
#--

use v6;

class Facter;

#se Facter::Util::Fact;
use Facter::Util::Collection;

our $VERSION = '0.02';

# TODO When outputting something
%*ENV<LANG> = 'C';

# Public members
has @.search_path is rw = ();

# Private members
has @!collection is rw;
has $!debug is rw = 0;
has $!timing is rw = 0;

method collection {
    unless defined @!collection {
        @!collection = Facter::Util::Collection.new
    }
    return @!collection;
}

method version () {
    return $VERSION
}

multi method debugging () {
    return $!debug != 0
}

# Set debugging on or off (1/0)
multi method debugging($bit) {
    if $bit {
        $!debug = 1;
    }
    else {
        $!debug = 0;
    }
}

method debug($string) {
    if ! defined $string {
        return
    }
    if self.debugging() {
        say $string
    }
    return;
}

method show_time($string) {
    if $string and self.timing {
        say $string
    }
    return;
}

multi method timing () {
    return $!timing != 0;
}

# Set timing on or off.
multi method timing($bit) {
    if $bit {
        $!timing = 1;
    } else {
        $!timing = 0;
    }
}

# Return a fact object by name.  If you use this, you still have to call
# 'value' on it to retrieve the actual value.
method get_fact($name) {
    self.collection.fact($name);
}

=begin ruby
    class << self
        [:fact, :flush, :list, :value].each do |method|
            define_method(method) do |*args|
                collection.send(method, *args)
            end
        end

        [:list, :to_hash].each do |method|
            define_method(method) do |*args|
                collection.load_all
                collection.send(method, *args)
            end
        end
    end
=end ruby

for 'fact', 'flush', 'value' -> $name {
    Facter.^add_method($name, method (*@args) {
        self.collection.^can($name).(@args);
    });
}

for 'list', 'to_hash' -> $name {
    Facter.^add_method($name, method (*@args) {
        self.collection.load_all();
        self.collection.^can($name, @args);
    });
}

# Add a resolution mechanism for a named fact.  This does not distinguish
# between adding a new fact and adding a new way to resolve a fact.
method add ($name, %options = (), &block) {
    self.collection.add($name, %options, &block)
}

method each () {
    self.collection.load_all();
    for self.collection.each -> $fact {
        yield($fact)
    }
}

# Clear all facts.  Mostly used for testing.
method clear () {
    self.flush();
    self.reset();
    return;
}

method warn ($msg) {
    if self.debugging and $msg and $msg != "" {
        $msg = [ $msg ] unless $msg.^can('each');
        for $msg -> $line {
            warn $line;
        }
    }
}

method reset () {
    @!collection = ();
}

# Load all of the default facts, and then everything from disk.
method loadfacts () {
    self.collection.load_all();
}

# Register a directory to search through.
method search(*@dirs) {
    @!search_path.push(@dirs);
}

# Return our registered search directories.
method search_path () {
    return @!search_path;
}

