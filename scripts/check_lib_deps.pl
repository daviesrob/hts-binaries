#!/usr/bin/env perl
#
# check_lib_deps.pl - check for unexpected shared library dependencies
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

# Allow linking against these libraries.
my %allowed = map { $_, 1 } qw(linux-vdso.so.1
libdl.so.2
libpthread.so.0
libc.so.6
libm.so.6
librt.so.1
/lib64/ld-linux-x86-64.so.2);

my $res = 0;
if (@ARGV) {
    foreach my $binary (@ARGV) {
	$res |= check($binary, \%allowed);
    }
} else {
    while (<STDIN>) {
	chomp;
	$res |= check($_, \%allowed);
    }
}
exit($res);

sub check {
    my ($binary, $allowed) = @_;

    my $res = 0;
    open(my $ldd, '-|', 'ldd', $binary)
	|| die "Couldn't open pipe to 'ldd $binary' : $!\n";
    while (<$ldd>) {
	chomp;
	my ($lib) = split;
	unless (exists($allowed{$lib})) {
	    print "$binary : $_\n";
	    $res = 1;
	}
    }
    close($ldd) || die "Error running 'ldd $binary'\n";
    return $res;
}
