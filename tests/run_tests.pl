#!/usr/bin/env perl

# run_tests.pl - run basic tests on samtools, bcftools binaries.

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
use FindBin;
use File::Spec;
use Getopt::Long;

my $do_https_tests = 0;
GetOptions("do-https-tests!" => \$do_https_tests)
    || die "Usage: $0 [-do_https_tests]\n";

my $https_test_file1 = "https://raw.githubusercontent.com/samtools/htslib/2be9e0b9b95c/test/range.bam";
my $https_test_file2 = "https://raw.githubusercontent.com/samtools/samtools/93bc9aae1af/test/dat/test_input_1_a.bam";

$ENV{REF_PATH} = ':';
my $bgzip = find_exe("bgzip");
my $tabix = find_exe("tabix");
my $samtools = find_exe("samtools");
my $bcftools = find_exe("bcftools");
my $htsfile = find_exe("htsfile");

my $samtools_result = '?';
my $bcftools_result = '?';
my $https_test1_result = 'Skipped';
my $https_test2_result = 'Skipped';
my $retval = 0;

# Do the https tests at the beginning and end to spread out requests to
# the server.
if ($do_https_tests) {
    if (https_test($htsfile, $https_test_file1, 0) == 0) {
	$https_test1_result = "Passed";
    } else {
	$https_test1_result = "Failed";
	$retval = 1;
    }
}

if (system("$FindBin::Bin/samtools/test/test.pl",
	   '--exec', "bgzip=$bgzip") == 0) {
    $samtools_result = 'Passed';
} else {
    $samtools_result = 'Failed';
    $retval = 1;
}

if (system("$FindBin::Bin/bcftools/test/test.pl",
	   '--exec', "bgzip=$bgzip", '--exec', "tabix=$tabix") == 0) {
    $bcftools_result = 'Passed';
} else {
    $bcftools_result = 'Failed';
    $retval = 1;
}

if ($do_https_tests) {
    if (https_test($htsfile, $https_test_file2, 1) == 0) {
	$https_test2_result = "Passed";
    } else {
	$https_test2_result = "Failed";
	$retval = 1;
    }
}


print "Samtools test.pl : $samtools_result\n";
print "BCFtools test.pl : $bcftools_result\n";
print "https test (default libcurl) : $https_test1_result\n";
print "https test (fallback libcurl): $https_test2_result\n";

exit $retval;

sub find_exe {
    my ($prog) = @_;

    foreach my $dir (File::Spec->path()) {
	if (-e "$dir/$prog") { return "$dir/$prog"; } 
    }

    die "run_tests.pl : Couldn't find $prog on PATH.\n";
}

sub https_test {
    my ($htsfile, $url, $use_fallback_libcurl) = @_;

    my $libcurl_dir = $htsfile;
    $libcurl_dir =~ s#/[^/]+$##;
    $libcurl_dir .= "/../lib/fallback";
    if (!-e "$libcurl_dir/libcurl.so.4") {
	warn "Couldn't find fallback libcurl\n(Looked in $libcurl_dir)\n";
	return -1;
    }
    local $ENV{LD_LIBRARY_PATH} = $libcurl_dir if ($use_fallback_libcurl);

    my $s;
    if (!open($s, '-|', "$htsfile", '-vvvvvvv', $url)) {
	warn "Couldn't open pipe to $samtools view -c '$url' : $!\n";
	return -1;
    }
    my ($result) = <$s>;
    if (!close($s)) {
	warn "Error running $samtools view -c '$url'\n";
	return -1;
    }
    unless ($result =~ /BAM version 1 compressed sequence data/) {
	warn "Unexpected result from $samtools view -c '$url'\nExpected:\n$url:\tBAM version 1 compressed sequence data\nGot:\n$result\n";
	return -1;
    }
    return 0;
}
