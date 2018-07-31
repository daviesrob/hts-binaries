# Build scripts to make binary distributions of HTSlib, SAMtools and BCFtools

This repository contains a make file that will build binary distributions for
HTSlib, SAMtools and BCFtools.

The distributions can be found on the [releases](../../releases) page.

The issue tracker for this repository should only be used for problems with
the build system itself.
Bug reports and feature requests on HTSlib, SAMtools and BCFtools should be
directed to the appropriate repository:

[HTSlib issue tracker](https://github.com/samtools/htslib/issues)

[SAMtools issue tracker](https://github.com/samtools/samtools/issues)

[BCFtools issue tracker](https://github.com/samtools/bcftools/issues)

# Building a distribution.

Ensure the tools needed to make the build are installed.
Note that `-dev` packages are not required as all dependencies are downloaded
and built by the Makefile rules.

On Debian / Ubuntu systems, use:

```
sudo apt update
sudo apt upgrade
sudo apt install git gcc make autoconf automake xz-utils pkg-config
```

Clone this repository:

```
git clone https://github.com/samtools/hts-binaries.git
```

Build the distribution:

```
cd hts-binaries
make && make test
```

It should make a tar file that can be copied to other machines and unpacked
to install the samtools, bcftools and other executables.

It will also make a tar file with test scripts and data that can be used to
check that the binaries work.

# Updating for new source versions

N.B.: The Makefile does very minimal tracking of source dependencies.
It make be necessary to do a `make clean` or remove specific targets to
get it to notice changes in the source repositories.

Update submodules, for example htslib:

```
cd sources/htslib
git fetch origin master
git checkout master
cd ../..
git add sources/htslib
git commit
```

Similarly for samtools and bcftools.

Update dependencies.
For zlib and libdeflate, update submodules to point at the latest release.
For the rest, update the Makefile variables `xz_version`, `bzip2_version`,
`ncurses_version`, `curl_version`, `gsl_version`, `gmp_version`,
`nettle_version`, `gnutls_version` to the latest upstream release.
Commit all changes.

Build the release and **test** it, both on the build system and on
target Linux distributions.
Also check that the readme file and copyright information have been produced
correctly.
