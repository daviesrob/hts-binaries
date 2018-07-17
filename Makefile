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
	cd sources/zlib && git clean -f -d -q -x && git reset --hard
	cd sources/libdeflate && git clean -f -d -q -x && git reset --hard
	cd sources/htslib && git clean -f -d -q -x && git reset --hard
	cd sources/samtools && git clean -f -d -q -x && git reset --hard
	cd sources/bcftools && git clean -f -d -q -x && git reset --hard

# Wrappers to deal with glibc versioned symbols
wrappers/glibc/libglibc_wrap.a: wrappers/glibc/glibc_wrap.o wrappers/glibc/glibm_wrap.o
	$(AR) -rc $@ $^

wrappers/glibc/glibc_wrap.o: wrappers/glibc/glibc_wrap.c

wrappers/glibc/glibm_wrap.o: wrappers/glibc/glibm_wrap.c

wrapper_ldflags = -Wl,--wrap=memcpy \
                  -Wl,--wrap=lgamma \
                  -Wl,--wrap=sscanf \
                  -Wl,--wrap=__isoc99_sscanf \
                  -Wl,--wrap=__fdelt_chk \
                  -Wl,--wrap=__stack_chk_fail \
                  -Wl,--hash-style=both

# Sources in submodules
# Create some variables for the dependencies used to get the submodules to
# update
sources_zlib = sources/zlib/configure
sources_libdeflate = sources/libdeflate/Makefile
sources_htslib = sources/htslib/configure.ac
sources_samtools = sources/samtools/configure.ac
sources_bcftools = sources/bcftools/configure.ac

$(sources_zlib):
	git submodule update sources/zlib

$(sources_libdeflate):
	git submodule update sources/libdeflate

$(sources_htslib):
	git submodule update sources/htslib

$(sources_samtools):
	git submodule update sources/samtools

$(sources_bcftools):
	git submodule update sources/bcftools

# Sources from release tar files
# Version numbers to expect
xz_version = 5.2.4
bzip2_version = 1.0.6

# Source tar files
xz_tar_file = xz-$(xz_version).tar.xz
bzip2_tar_file = bzip2-$(bzip2_version).tar.gz

# Source directories
sources_xz = sources/xz-$(xz_version)
sources_bzip2 = sources/bzip2-$(bzip2_version)

# Get tar files

sources/$(xz_tar_file):
	cd sources && wget https://www.tukaani.org/xz/$(xz_tar_file)

sources/$(bzip2_tar_file):
	cd sources && wget http://bzip.org/$(bzip2_version)/$(bzip2_tar_file)

# Unpack tars

$(sources_xz)/configure: sources/$(xz_tar_file)
	cd sources && tar xvJf $(xz_tar_file) && touch ../$(sources_xz)/configure

$(sources_bzip2)/Makefile: sources/$(bzip2_tar_file)
	cd sources && tar xvzf $(bzip2_tar_file) && touch ../$(sources_bzip2)/Makefile

# Build libz.a
sources/zlib/libz.a: $(sources_zlib)
	cd sources/zlib && \
	CFLAGS='-g -O3 -fpic' ./configure --static && \
	$(MAKE) clean && \
	$(MAKE)

# Build libdeflate.a
sources/libdeflate/libdeflate.a: $(sources_libdeflate)
	cd sources/libdeflate && \
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

# Build htslib
sources/htslib/configure: $(sources_htslib)
	cd sources/htslib && \
	autoconf && \
	autoheader

staging/lib/libhts.a: sources/htslib/configure \
                      $(sources_bzip2)/libbz2.a \
                      $(sources_xz)/liblzma.a \
                      sources/libdeflate/libdeflate.a \
                      sources/zlib/libz.a \
                      wrappers/glibc/libglibc_wrap.a
	cd sources/htslib && \
	$(MAKE) distclean && \
	./configure CPPFLAGS='-I../zlib -I../libdeflate -I../../$(sources_bzip2) -I../../$(sources_xz)' \
	            LDFLAGS='-L../../wrappers/glibc -L../zlib -L../libdeflate -L../../$(sources_bzip2) -L../../$(sources_xz) $(wrapper_ldflags)' \
                    LIBS='-lglibc_wrap' \
                    --disable-libcurl \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

# Build samtools
sources/samtools/configure: $(sources_samtools)
	cd sources/samtools && \
	autoconf && \
	autoheader

staging/bin/samtools: staging/lib/libhts.a wrappers/glibc/libglibc_wrap.a sources/samtools/configure
	cd sources/samtools && \
	$(MAKE) distclean && \
	./configure CPPFLAGS='-I../zlib' \
	            LDFLAGS='-L../../wrappers/glibc -L../zlib $(wrapper_ldflags)' \
                    LIBS='-lglibc_wrap' \
                    --without-curses \
                    --prefix="$$(pwd -P)/../../staging" && \
	$(MAKE) && \
	$(MAKE) install

# The tar file itself
$(tar_root).tgz: staging/lib/libhts.a staging/bin/samtools
	tar -cvzf $@ --show-transformed-names --transform 's,staging,$(tar_root),' --mode=og-w --owner=root --group=root staging

.PHONY: all clean clean-staging clean-tarfile
