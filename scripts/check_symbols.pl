#!/usr/bin/env perl
#
# check_symbols.pl - check for versioned symbols
#
#     Copyright (c) 2018 Genome Research Ltd.
#
#     Author: Rob Davies <rmd@sanger.ac.uk>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

use strict;
use warnings;
use version 0.77;

# These are the library versions that we're targeting.
my %targets = (GLIBC => '2.3.4');

my $res = 0;
if (@ARGV) {
    foreach my $binary (@ARGV) {
	$res |= check($binary, \%targets);
    }
} else {
    while (<STDIN>) {
	chomp;
	$res |= check($_, \%targets);
    }
}
exit($res);

sub check {
    my ($binary, $targets) = @_;

    my $res = 0;
    my $tgts = join('|', keys %$targets);
    my $tgts_re = qr/($tgts)_(\d+(?:\.\d+)*)/;
    open(my $objdump, '-|', 'objdump', '-T', $binary)
	|| die "Couldn't open pipe to objdump -T $binary: $!\n";
    while (<$objdump>) {
	chomp;
	if (/^[0-9a-f]+ [lgu! ][w ][C ][W ][Ii ][Dd ][FfO ] \S+\t[0-9a-f]+\s+(\S+)\s+(\S+)$/) {
	    my ($sym_vers, $symbol) = ($1, $2);
	    if ($sym_vers =~ /$tgts_re/) {
		my ($lib, $vers) = ($1, $2);
		next unless (exists($targets->{$lib}));
		if (version->parse("v$vers") > version->parse("v$targets->{$lib}")) {
		    print "$binary: $_\n";
		    $res = 1;
		}
	    }
	}
    }
    close($objdump) || die "Error running objdump -T $binary\n";
    return $res;
}
