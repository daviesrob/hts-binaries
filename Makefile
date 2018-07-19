# Root directory for the binaries tar file
tar_root = htstools-glibc

all: $(tar_root).tgz

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -fpic -c -o $@ $<

clean-tarfile:
	-rm -f $(tar_root).tgz

clean-staging: clean-tarfile
	-rm -rf staging/*

clean: clean-staging
	-rm -f wrappers/glibc/*.o wrappers/glibc/*.a
	-rm -rf sources/xz-*/ sources/bzip2-*/
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

# Source tar files
xz_tar_file = xz-$(xz_version).tar.xz
bzip2_tar_file = bzip2-$(bzip2_version).tar.gz
ncurses_tar_file = ncurses-$(ncurses_version).tar.gz

# Source directories
sources_xz = sources/xz-$(xz_version)
sources_bzip2 = sources/bzip2-$(bzip2_version)
sources_ncurses = sources/ncurses-$(ncurses_version)

# Get tar files

sources/$(xz_tar_file):
	cd sources && wget https://www.tukaani.org/xz/$(xz_tar_file)

sources/$(bzip2_tar_file):
	cd sources && wget http://bzip.org/$(bzip2_version)/$(bzip2_tar_file)

sources/$(ncurses_tar_file):
	cd sources && wget https://invisible-mirror.net/archives/ncurses/$(ncurses_tar_file)

# Unpack tars

$(sources_xz)/configure $(sources_xz)/COPYING: sources/$(xz_tar_file)
	cd sources && tar xvJf $(xz_tar_file) && touch ../$(sources_xz)/configure ../$(sources_xz)/COPYING

$(sources_bzip2)/Makefile $(sources_bzip2)/LICENSE: sources/$(bzip2_tar_file)
	cd sources && tar xvzf $(bzip2_tar_file) && touch ../$(sources_bzip2)/Makefile ../$(sources_bzip2)/LICENSE

$(sources_ncurses)/configure $(sources_ncurses)/COPYING: sources/$(ncurses_tar_file)
	cd sources && tar xvzf $(ncurses_tar_file) && touch ../$(sources_ncurses)/configure ../$(sources_ncurses)/COPYING

# Build libz.a
$(sources_zlib)/libz.a: $(sources_zlib)/configure
	cd $(sources_zlib) && \
	CFLAGS='-g -O3 -fpic' ./configure --static && \
	$(MAKE) clean && \
	$(MAKE)

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
                      wrappers/libcurl/libcurl.a
	cd $(sources_htslib) && \
	$(MAKE) distclean && \
	./configure CPPFLAGS='-I../zlib -I../libdeflate -I../../$(sources_bzip2) -I../../$(sources_xz) -I../../wrappers/libcurl' \
	            LDFLAGS='-L../../wrappers/glibc -L../zlib -L../libdeflate -L../../$(sources_bzip2) -L../../$(sources_xz) $(wrapper_ldflags) -L../../wrappers/libcurl' \
                    LIBS='-lglibc_wrap -lcurl -ldl' \
                    --disable-s3 \
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
	            LDFLAGS='-L../../wrappers/glibc -L../zlib -L../../built_deps/lib $(wrapper_ldflags)' \
                    LIBS='-lncurses -lglibc_wrap -ldl' \
                    --with-ncurses \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

copyright: copyright_samtools copyright_htslib copyright_bcftools \
           copyright_zlib copyright_bzip2 copyright_xz copyright_libdeflate \
           copyright_ncurses

copyright_samtools: staging/share/doc/samtools/copyright
copyright_htslib: staging/share/doc/htslib/copyright
copyright_bcftools: staging/share/doc/bcftools/copyright
copyright_zlib: staging/share/doc/zlib/copyright
copyright_bzip2:  staging/share/doc/bzip2/copyright
copyright_xz: staging/share/doc/xz/copyright
copyright_libdeflate: staging/share/doc/libdeflate/copyright
copyright_ncurses: staging/share/doc/ncurses/copyright

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
	perl -lne 'if (/^Acknowledgments::/) { $$p = 1; } if ($$p) { print; } if (/\s+jloup@gzip\.org\s+madler@alumni\.caltech\.edu/) { $$p = 0; }' $(sources_zlib)/README > $@

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

# The tar file itself
$(tar_root).tgz: staging/lib/libhts.a staging/bin/samtools copyright
	tar -cvzf $@ --show-transformed-names --transform 's,staging,$(tar_root),' --mode=og-w --owner=root --group=root staging

.PHONY: all clean clean-staging clean-tarfile \
  copyright copyright_samtools copyright_htslib copyright_bcftools \
  copyright_zlib copyright_bzip2 copyright_xz copyright_libdeflate \
  copyright_ncurses
