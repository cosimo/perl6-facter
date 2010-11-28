Facter.add("perl6os", sub ($f) {
    Facter.debug("perl6os fact block running");
    $f.setcode(block => sub {
        $*OS.Str
    });
})

