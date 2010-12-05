Facter.add("physicalprocessorcount", sub ($f) {
    # TODO kernel fact not available yet
    #$f.confine("kernel", "linux");
    $f.setcode(block => sub {
        Facter::Util::Resolution.exec('grep "physical id" /proc/cpuinfo|cut -d: -f 2|sort -u|wc -l');
    });
});

