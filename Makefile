# Target for build
target = x86_64-linux-glibc

# Root directory for the binaries tar file
tar_root = htstools-$(target)

# some directories
abs_built_deps=$(CURDIR)/built_deps

CFLAGS=-g -O3 -Wall -fpic

all: $(tar_root).tgz

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -fpic -c -o $@ $<

clean-tarfile:
	-rm -f $(tar_root).tgz

clean-staging: clean-tarfile
	-rm -rf staging/*

clean: clean-staging
	-rm -f wrappers/glibc/*.o wrappers/glibc/*.a
	-rm -f wrappers/libcurl/*.o wrappers/libcurl/*.a
	-rm -f wrappers/crypto/*.o wrappers/crypto/*.a
	-rm -rf sources/xz-*/ sources/bzip2-*/ sources/curl-*/ sources/gsl-*/
	-rm -rf sources/gmp-*/ sources/nettle-*/ sources/gnutls-*/
	cd $(sources_zlib) && git clean -f -d -q -x && git reset --hard
	cd $(sources_libdeflate) && git clean -f -d -q -x && git reset --hard
	cd $(sources_htslib) && git clean -f -d -q -x && git reset --hard
	cd $(sources_samtools) && git clean -f -d -q -x && git reset --hard
	cd $(sources_bcftools) && git clean -f -d -q -x && git reset --hard

# Wrappers to deal with glibc versioned symbols
wrappers/glibc/libglibc_wrap.a: wrappers/glibc/glibc_wrap.o wrappers/glibc/glibm_wrap.o
	$(AR) -rc $@ $^

wrappers/glibc/glibc_wrap.o: wrappers/glibc/glibc_wrap.c

wrappers/glibc/glibm_wrap.o: wrappers/glibc/glibm_wrap.c

wrapper_ldflags = -Wl,--wrap=memcpy \
                  -Wl,--wrap=lgamma \
                  -Wl,--wrap=scanf \
                  -Wl,--wrap=__isoc99_scanf \
                  -Wl,--wrap=sscanf \
                  -Wl,--wrap=__isoc99_sscanf \
                  -Wl,--wrap=fscanf \
                  -Wl,--wrap=__isoc99_fscanf \
                  -Wl,--wrap=__fdelt_chk \
                  -Wl,--wrap=__stack_chk_fail \
                  -Wl,--wrap=__vasprintf_chk \
                  -Wl,--hash-style=both

# Wrapper around libcurl
wrappers/libcurl/libcurl.a: wrappers/libcurl/libcurl_wrap.o
	$(AR) -rc $@ $^

wrappers/libcurl/libcurl_wrap.o: wrappers/libcurl/libcurl_wrap.c wrappers/libcurl/curl/curl.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -Iwrappers/libcurl -fpic -c -o $@ $<

# Sources in submodules
# Create some variables for the source directories
sources_zlib = sources/zlib
sources_libdeflate = sources/libdeflate
sources_htslib = sources/htslib
sources_samtools = sources/samtools
sources_bcftools = sources/bcftools

$(sources_zlib)/configure $(sources_zlib)/README:
	git submodule update $(sources_zlib)

$(sources_libdeflate)/Makefile $(sources_libdeflate)/COPYING:
	git submodule update $(sources_libdeflate)

$(sources_htslib)/configure.ac $(sources_htslib)/LICENSE:
	git submodule update $(sources_htslib)

$(sources_samtools)/configure.ac $(sources_samtools)/LICENSE:
	git submodule update $(sources_samtools)

$(sources_bcftools)/configure.ac $(sources_bcftools)/LICENSE:
	git submodule update $(sources_bcftools)

# Sources from release tar files
# Version numbers to expect
xz_version = 5.2.4
bzip2_version = 1.0.6
ncurses_version = 6.1
curl_version = 7.61.0
gsl_version = 2.5
# Needed for gnutls + dependencies
gmp_version = 6.1.2
nettle_version = 3.4
gnutls_version = 3.5.19

# Source tar files
xz_tar_file = xz-$(xz_version).tar.xz
bzip2_tar_file = bzip2-$(bzip2_version).tar.gz
ncurses_tar_file = ncurses-$(ncurses_version).tar.gz
curl_tar_file = curl-$(curl_version).tar.xz
gsl_tar_file = gsl-$(gsl_version).tar.gz
# Tar files for gnutls + dependencies
gmp_tar_file = gmp-$(gmp_version).tar.xz
nettle_tar_file = nettle-$(nettle_version).tar.gz
gnutls_tar_file = gnutls-$(gnutls_version).tar.xz

# Source directories
sources_xz = sources/xz-$(xz_version)
sources_bzip2 = sources/bzip2-$(bzip2_version)
sources_ncurses = sources/ncurses-$(ncurses_version)
sources_curl = sources/curl-$(curl_version)
sources_gsl = sources/gsl-$(gsl_version)
# Sources for gnutls + dependencies
sources_gmp = sources/gmp-$(gmp_version)
sources_nettle = sources/nettle-$(nettle_version)
sources_gnutls = sources/gnutls-$(gnutls_version)

# Get tar files

sources/$(xz_tar_file):
	cd sources && wget https://www.tukaani.org/xz/$(xz_tar_file)

sources/$(bzip2_tar_file):
	cd sources && wget http://bzip.org/$(bzip2_version)/$(bzip2_tar_file)

sources/$(ncurses_tar_file):
	cd sources && wget https://invisible-mirror.net/archives/ncurses/$(ncurses_tar_file)

sources/$(curl_tar_file):
	cd sources && wget https://curl.haxx.se/download/$(curl_tar_file)

sources/$(gsl_tar_file):
	cd sources && wget https://ftpmirror.gnu.org/gsl/$(gsl_tar_file)

sources/$(gmp_tar_file):
	cd sources && wget https://gmplib.org/download/gmp/$(gmp_tar_file)

sources/$(nettle_tar_file):
	cd sources && wget https://ftp.gnu.org/gnu/nettle/$(nettle_tar_file)

sources/$(gnutls_tar_file):
	cd sources && wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.5/$(gnutls_tar_file)

# Unpack tars

$(sources_xz)/configure $(sources_xz)/COPYING: sources/$(xz_tar_file)
	cd sources && tar xvJf $(xz_tar_file) && touch ../$(sources_xz)/configure ../$(sources_xz)/COPYING

$(sources_bzip2)/Makefile $(sources_bzip2)/LICENSE: sources/$(bzip2_tar_file)
	cd sources && tar xvzf $(bzip2_tar_file) && touch ../$(sources_bzip2)/Makefile ../$(sources_bzip2)/LICENSE

$(sources_ncurses)/configure $(sources_ncurses)/COPYING: sources/$(ncurses_tar_file)
	cd sources && tar xvzf $(ncurses_tar_file) && touch ../$(sources_ncurses)/configure ../$(sources_ncurses)/COPYING

$(sources_curl)/configure $(sources_curl)/COPYING: sources/$(curl_tar_file)
	cd sources && tar xvJf $(curl_tar_file) && touch ../$(sources_curl)/configure  ../$(sources_curl)/COPYING

$(sources_gsl)/configure $(sources_gsl)/COPYING: sources/$(gsl_tar_file)
	cd sources && tar xvzf $(gsl_tar_file) && touch ../$(sources_gsl)/configure ../$(sources_gsl)/COPYING

$(sources_gmp)/configure $(sources_gmp)/README: sources/$(gmp_tar_file)
	cd sources && tar xvJf $(gmp_tar_file) && touch ../$(sources_gmp)/configure ../$(sources_gmp)/README

$(sources_nettle)/configure $(sources_nettle)/nettle.texinfo: sources/$(nettle_tar_file)
	cd sources && tar xvzf $(nettle_tar_file) && touch ../$(sources_nettle)/configure ../$(sources_nettle)/nettle.texinfo

$(sources_gnutls)/configure $(sources_gnutls)/LICENSE: sources/$(gnutls_tar_file)
	cd sources && tar xvJf $(gnutls_tar_file) && touch ../$(sources_gnutls)/configure ../$(sources_gnutls)/LICENSE

# Build libz.a
$(sources_zlib)/libz.a built_deps/lib/libz.a: $(sources_zlib)/configure
	cd $(sources_zlib) && \
	CFLAGS='-g -O3 -fpic' ./configure --static --prefix=$$(pwd -P)/../../built_deps && \
	$(MAKE) clean && \
	$(MAKE) && \
	$(MAKE) install

# Build libdeflate.a
$(sources_libdeflate)/libdeflate.a: $(sources_libdeflate)/Makefile
	cd $(sources_libdeflate) && \
	$(MAKE) clean && \
	$(MAKE) libdeflate.a CFLAGS='-g -O3 -fpic'

# Build liblzma.a
$(sources_xz)/liblzma.a: $(sources_xz)/configure
	cd $(sources_xz) && \
	./configure --disable-xz --disable-xzdec --disable-lzmadec \
	   --disable-lzmainfo --disable-lzma-links --disable-scripts \
	   --disable-doc --disable-shared CFLAGS='-g -O3 -fpic' && \
	$(MAKE) clean && \
	$(MAKE) && \
	cp -av src/liblzma/.libs/liblzma.a ./liblzma.a

# Build libbz2.a
$(sources_bzip2)/libbz2.a: $(sources_bzip2)/Makefile
	cd $(sources_bzip2) && \
	$(MAKE) CFLAGS='-g -O3 -fpic -D_FILE_OFFSET_BITS=64'

# Build libcurses.a
built_deps/lib/libncurses.a: $(sources_ncurses)/configure
	cd $(sources_ncurses) && \
	./configure --without-cxx --without-progs --disable-db-install --disable-home-terminfo --enable-const --enable-termcap --without-gpm --with-normal --without-dlsym --without-manpages --without-tests --with-terminfo-dirs=/etc/terminfo:/lib/terminfo:/usr/share/terminfo -with-default-terminfo-dir=/usr/share/terminfo --with-termpath=/etc/termcap:/usr/share/misc/termcap --prefix=$$(pwd -P)/../../built_deps && \
	$(MAKE) clean && $(MAKE) && $(MAKE) install

# Build libgsl.a
built_deps/lib/libgsl.a: $(sources_gsl)/configure
	cd $(sources_gsl) && \
	./configure --with-pic --enable-static --disable-shared \
	            --prefix=$(abs_built_deps) && \
	$(MAKE) clean && \
	$(MAKE) && \
	$(MAKE) install

# libgnutls + dependencies
# gmp
built_deps/lib/libgmp.a: $(sources_gmp)/configure
	cd $(sources_gmp) && \
	./configure --enable-fat --disable-shared \
	            --prefix=$$(pwd -P)/../../built_deps \
	            CFLAGS='-g -O3 -fpic' && \
	$(MAKE) clean && \
	$(MAKE) V=1 && \
	$(MAKE) install

# nettle
built_deps/lib/libnettle.a: $(sources_nettle)/configure built_deps/lib/libgmp.a
	cd $(sources_nettle) && \
	./configure --disable-shared --prefix=$$(pwd -P)/../../built_deps \
	            CPPFLAGS="-I$$(pwd -P)/../../built_deps" \
	            LDFLAGS="-L$$(pwd -P)/../../built_deps" \
	            CFLAGS="-g -O3 -fpic" && \
	$(MAKE) clean && \
	$(MAKE) && \
	$(MAKE) install

# gnutls itself
built_deps/lib/libgnutls.a: $(sources_gnutls)/configure built_deps/lib/libnettle.a
	cd $(sources_gnutls) && \
	PKG_CONFIG_PATH=$$(pwd -P)/../../built_deps/lib/pkgconfig \
	./configure --disable-doc --disable-cxx --disable-dtls-srtp-support \
	            --disable-nls --disable-rpath --disable-nls \
	            --disable-guile --without-p11-kit --without-tpm \
	            --with-included-libtasn1 --with-included-unistring \
	            --without-idn --without-libidn2 \
	            --enable-static --disable-shared \
	            --prefix=$(abs_built_deps) \
	            CFLAGS='-g -O3 -fpic' \
	            CPPFLAGS='-I$(abs_built_deps)/include' \
	            LDFLAGS='-L$(abs_built_deps)/lib' && \
	$(MAKE) && \
	$(MAKE) install

# Build libcurl
built_deps/lib/libcurl.so: $(sources_curl)/configure \
                           built_deps/lib/libz.a \
                           built_deps/lib/libgnutls.a \
                           wrappers/glibc/libglibc_wrap.a
	cd $(sources_curl) && \
	./configure --enable-symbol-hiding --disable-ares --enable-rt \
	            --disable-static --disable-file --disable-ldap \
	            --disable-ldaps --disable-rtsp --disable-dict \
	            --disable-telnet --disable-tftp --disable-pop3 \
	            --disable-imap --disable-smb --disable-smtp \
	            --disable-manual --enable-ipv6 --disable-versioned-symbols \
	            --enable-threaded-resolver --enable-pthreads \
	            --disable-verbose --disable-sspi --disable-ntlm-wb \
	            --disable-unix-sockets --without-brotli --without-gssapi \
	            --without-libpsl --without-libmetalink \
	            --without-libssh2 --without-libssh --without-librtmp \
	            --without-nghttp2 --with-zlib=$(abs_built_deps) \
	            --without-ssl  --with-gnutls=$(abs_built_deps) \
	            --prefix=$(abs_built_deps) \
	            CPPFLAGS='-I$(abs_built_deps)/include' \
	            LDFLAGS='-L$(abs_built_deps)/lib '-L$$(pwd -P)'/../../wrappers/glibc $(wrapper_ldflags)' \
	            LIBS='-lnettle -lhogweed -lgmp -lglibc_wrap' && \
	$(MAKE) clean && \
	$(MAKE) && \
	$(MAKE) install

# Fallback libcurl
staging/lib/fallback/libcurl.so: built_deps/lib/libcurl.so
	mkdir -p staging/lib/fallback && \
	cp built_deps/lib/libcurl.so* staging/lib/fallback && \
	touch $@

# OpenSSL replacement
# As we're building nettle (used by gnutls) for libcurl, we may as well use it
# for the HMAC() function htslib usually gets from openssl.
wrappers/crypto/crypto.o: wrappers/crypto/crypto.c built_deps/lib/libgnutls.a
	$(CC) $(CFLAGS) $(CPPFLAGS) -Ibuilt_deps/include -fpic -c -o $@ $<

wrappers/crypto/libcrypto.a: wrappers/crypto/crypto.o
	$(AR) -rc $@ $^

# Build htslib
$(sources_htslib)/configure: $(sources_htslib)/configure.ac
	cd $(sources_htslib) && \
	autoconf && \
	autoheader

staging/lib/libhts.a: $(sources_htslib)/configure \
                      $(sources_bzip2)/libbz2.a \
                      $(sources_xz)/liblzma.a \
                      $(sources_libdeflate)/libdeflate.a \
                      $(sources_zlib)/libz.a \
                      wrappers/glibc/libglibc_wrap.a \
                      wrappers/libcurl/libcurl.a \
                      wrappers/crypto/libcrypto.a \
                      built_deps/lib/libcurl.so \
                      built_deps/lib/libnettle.a
	cd $(sources_htslib) && \
	$(MAKE) distclean && \
	./configure CFLAGS='-g -O3 -Wall -fpic' \
	            CPPFLAGS='-I../zlib -I../libdeflate -I../../$(sources_bzip2) -I../../$(sources_xz) -I../../wrappers/libcurl -I../../wrappers/crypto -I../../built-deps/include' \
	            LDFLAGS='-L../../wrappers/glibc -L../zlib -L../libdeflate -L../../$(sources_bzip2) -L../../$(sources_xz) $(wrapper_ldflags) -L../../wrappers/libcurl -L../../wrappers/crypto -L../../built_deps/lib -Wl,--exclude-libs,libcrypto.a:libz.a:libnettle.a:libdeflate.a:liblzma.a:libbz2.a:libglibc_wrap.a -Wl,--gc-sections' \
                    LIBS='-lcrypto -lnettle -lcurl -lglibc_wrap -ldl' \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

# Build samtools
$(sources_samtools)/configure: $(sources_samtools)/configure.ac
	cd $(sources_samtools) && \
	autoconf && \
	autoheader

# Note -lncurses needs to be added to LIBS as otherwise the configure
# curses detection fails (it puts -lncurses after -lglibc_wrap so the
# wrapper symbols can't be found)
staging/bin/samtools: $(sources_samtools)/configure \
                      built_deps/lib/libncurses.a \
                      staging/lib/libhts.a \
                      wrappers/glibc/libglibc_wrap.a
	cd $(sources_samtools) && \
	$(MAKE) distclean && \
	./configure CPPFLAGS='-I../zlib -I../../built_deps/include' \
	            LDFLAGS='-L../../wrappers/glibc -L../zlib -L../../built_deps/lib $(wrapper_ldflags) -Wl,--gc-sections' \
                    LIBS='-lcrypto -lnettle -lncurses -lglibc_wrap -ldl' \
                    --with-ncurses \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

# Build bcftools
# Some code that we can inject to get bcftools to find its plugins

wrappers/bcftools-plugin/liblocate_plugins.a: wrappers/bcftools-plugin/locate_plugins.o
	$(AR) -rc $@ $^

wrappers/bcftools-plugin/locate_plugins.o: wrappers/bcftools-plugin/locate_plugins.c wrappers/bcftools-plugin/locate_plugins.h

$(sources_bcftools)/configure: $(sources_bcftools)/configure.ac
	cd $(sources_bcftools) && \
	autoconf && \
	autoheader

staging/bin/bcftools: $(sources_bcftools)/configure \
                      staging/lib/libhts.a \
	              built_deps/lib/libgsl.a \
                      wrappers/glibc/libglibc_wrap.a \
	              wrappers/bcftools-plugin/liblocate_plugins.a \
	              wrappers/bcftools-plugin/locate_plugins.h
	cd $(sources_bcftools) && \
	$(MAKE) distclean && \
	./configure CPPFLAGS='-I../zlib -I../../built_deps/include -include ../../wrappers/bcftools-plugin/locate_plugins.h' \
	            LDFLAGS='-L../../wrappers/glibc -L../../wrappers/bcftools-plugin -L../zlib -L../../built_deps/lib $(wrapper_ldflags) -Wl,--exclude-libs,libcrypto.a:libz.a:libnettle.a:libdeflate.a:liblzma.a:libbz2.a:libglibc_wrap.a:liblocate_plugins.a -Wl,--gc-sections' \
                    LIBS='-lm -lcrypto -lnettle -llocate_plugins -lglibc_wrap -ldl' \
	            --enable-libgsl --with-cblas=gslcblas \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

copyright: copyright_samtools copyright_htslib copyright_bcftools \
           copyright_zlib copyright_bzip2 copyright_xz copyright_libdeflate \
           copyright_ncurses copyright_libcurl copyright_gmp copyright_nettle \
           copyright_gnutls copyright_gsl

copyright_samtools: staging/share/doc/samtools/copyright
copyright_htslib: staging/share/doc/htslib/copyright
copyright_bcftools: staging/share/doc/bcftools/copyright
copyright_zlib: staging/share/doc/zlib/copyright
copyright_bzip2:  staging/share/doc/bzip2/copyright
copyright_xz: staging/share/doc/xz/copyright
copyright_libdeflate: staging/share/doc/libdeflate/copyright
copyright_ncurses: staging/share/doc/ncurses/copyright
copyright_gsl: staging/share/doc/gsl/copyright
copyright_libcurl: staging/share/doc/libcurl/copyright
copyright_gmp: staging/share/doc/gmp/copyright
copyright_nettle: staging/share/doc/nettle/copyright
copyright_gnutls: staging/share/doc/gnutls/copyright

staging/share/doc/samtools/copyright: $(sources_samtools)/LICENSE
	mkdir -p staging/share/doc/samtools && \
	cp $(sources_samtools)/LICENSE $@

staging/share/doc/htslib/copyright: $(sources_htslib)/LICENSE
	mkdir -p staging/share/doc/htslib && \
	cp $(sources_htslib)/LICENSE $@

staging/share/doc/bcftools/copyright: $(sources_bcftools)/LICENSE
	mkdir -p staging/share/doc/bcftools && \
	cp $(sources_bcftools)/LICENSE $@

staging/share/doc/zlib/copyright: $(sources_zlib)/README
	mkdir -p staging/share/doc/zlib && \
	perl -lne 'if (/^Acknowledgments:/) { $$p = 1; } if ($$p) { print; } if (/\s+jloup\@gzip\.org\s+madler\@alumni\.caltech\.edu/) { $$p = 0; }' $(sources_zlib)/README > $@

staging/share/doc/bzip2/copyright: $(sources_bzip2)/LICENSE
	mkdir -p staging/share/doc/bzip2 && \
	cp $(sources_bzip2)/LICENSE $@

staging/share/doc/xz/copyright: $(sources_xz)/COPYING
	mkdir -p staging/share/doc/xz && \
	echo 'This software includes liblzma code from XZ Utils <https://tukaani.org/xz/>.' > $@ && \
	echo 'No other part of XZ is included.' >> $@ && \
	cat $(sources_xz)/COPYING >> $@

staging/share/doc/libdeflate/copyright: $(sources_libdeflate)/COPYING
	mkdir -p staging/share/doc/libdeflate && \
	cp $(sources_libdeflate)/COPYING $@

staging/share/doc/ncurses/copyright: $(sources_ncurses)/COPYING
	mkdir -p staging/share/doc/ncurses && \
	cp $(sources_ncurses)/COPYING $@

staging/share/doc/gsl/copyright: $(sources_gsl)/COPYING
	mkdir -p staging/share/doc/gsl && \
	cp $(sources_gsl)/COPYING $@

staging/share/doc/libcurl/copyright: $(sources_curl)/COPYING
	mkdir -p staging/share/doc/libcurl && \
	cp $(sources_curl)/COPYING $@

staging/share/doc/gmp/copyright: $(sources_gmp)/README
	mkdir -p staging/share/doc/gmp && \
	printf 'From gmp-$(gmp_version)/README:\n\n' > $@.tmp && \
	perl -pe 'if (/^\s+THE GNU MP LIBRARY\s+$$/) { exit; }' $(sources_gmp)/README >> $@.tmp && \
	printf '\n========================================================================\n\n' >> $@.tmp && \
	printf 'The copy of gmp in this package is distributed under the terms of the\nGNU Lesser General Public License version 3.\n\n' >> $@.tmp && \
	cat $(sources_gmp)/COPYING.LESSERv3 >> $@.tmp && \
	mv -f $@.tmp $@

staging/share/doc/nettle/copyright: $(sources_nettle)/nettle.texinfo
	mkdir -p staging/share/doc/nettle && \
	echo 'From nettle-$(nettle_version)/nettle.texinfo:' > $@.tmp && \
	perl -ne 'if (/^\@chapter Copyright/) { $$p = 1; next; } if (/^This manual is in the public domain/) { $$p = 0; last; } if ($$p) { print }' $(sources_nettle)/nettle.texinfo >> $@.tmp && \
	printf '\n========================================================================\n\n' >> $@.tmp && \
	printf 'The copy of nettle in this package is distributed under the terms of the\nGNU Lesser General Public License version 3.\n\n' >> $@.tmp && \
	cat $(sources_nettle)/COPYING.LESSERv3 >> $@.tmp && \
	mv -f $@.tmp $@

# Borrow nettle's copy of LGPLv3 for this
staging/share/doc/gnutls/copyright: $(sources_gnutls)/LICENSE $(sources_nettle)/nettle.texinfo
	mkdir -p staging/share/doc/gnutls && \
	printf 'From gnutls-$(gnutls_version)/LICENSE:\n\n' > $@.tmp && \
	cat $(sources_gnutls)/LICENSE >> $@.tmp && \
	printf '\n========================================================================\n\n' >> $@.tmp && \
	printf 'The copy of gnutls in this package is distributed under the terms of the\nGNU Lesser General Public License version 3.\n\n' >> $@.tmp && \
	cat $(sources_nettle)/COPYING.LESSERv3 >> $@.tmp && \
	mv -f $@.tmp $@

# README file
staging/README.$(target).txt : texts/readme.$(target).template \
                               staging/bin/samtools \
                               staging/bin/bcftools
	cp texts/readme.$(target).template $@.tmp && \
	printf '\nCurrent build system revision:\n' >> $@.tmp && \
	git rev-parse --verify HEAD >> $@.tmp && \
	git status -s >> $@.tmp && \
	printf '\nRevisions used for sources obtained via git:\n\n' >> $@.tmp && \
	git submodule status >> $@.tmp && \
	printf '\nSHA224 checksums of downloaded source archive files:\n\n' >> $@.tmp && \
	( cd sources && sha224sum $(bzip2_tar_file) $(curl_tar_file) \
             $(gmp_tar_file) $(gnutls_tar_file) $(gsl_tar_file) \
             $(ncurses_tar_file) $(nettle_tar_file) $(xz_tar_file) ) >> $@.tmp && \
	printf '\nBuild host : ' >> $@.tmp && \
	uname -s -r -v -m -o >> $@.tmp && \
	perl -ne 'if (/^model name/) { s/.*?:\s+//; print "CPU model : $$_"; last; }' /proc/cpuinfo >> $@.tmp && \
	printf '\nCompiler information (gcc -v):\n' >> $@.tmp && \
	gcc -v >> $@.tmp 2>&1 && \
	printf '\nLinker version (ld -v):\n' >> $@.tmp && \
	ld -v >> $@.tmp && \
	mv $@.tmp $@

# The tar file itself
$(tar_root).tgz: staging/lib/libhts.a \
                 staging/bin/samtools \
                 staging/bin/bcftools \
                 staging/lib/fallback/libcurl.so \
                 staging/README.$(target).txt \
                 copyright
	tar -cvzf $@ --show-transformed-names \
	    --transform 's,staging,$(tar_root),' \
	    --exclude=staging/lib/libhts.a \
	    --exclude=staging/lib/pkgconfig \
	    --mode=og-w --owner=root --group=root staging

.PHONY: all clean clean-staging clean-tarfile \
  copyright copyright_samtools copyright_htslib copyright_bcftools \
  copyright_zlib copyright_bzip2 copyright_xz copyright_libdeflate \
  copyright_ncurses
