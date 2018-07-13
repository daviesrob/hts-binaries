all: wrappers/glibc/libglibc_wrap.a

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -fpic -c -o $@ $<

clean:
	-rm -f wrappers/glibc/*.o wrappers/glibc/*.a
	-rm -rf sources/xz-*/ sources/bzip2-*/
	cd sources/zlib && git clean -f -d -q -x && git reset --hard
	cd sources/libdeflate && git clean -f -d -q -x && git reset --hard

# Wrappers to deal with glibc versioned symbols
wrappers/glibc/libglibc_wrap.a: wrappers/glibc/glibc_wrap.o wrappers/glibc/glibm_wrap.o
	$(AR) -rc $@ $^

wrappers/glibc/glibc_wrap.o: wrappers/glibc/glibc_wrap.c

wrappers/glibc/glibm_wrap.o: wrappers/glibc/glibm_wrap.c

# Sources in submodules
# Create some variables for the dependencies used to get the submodules to
# update
sources_zlib = sources/zlib/configure
sources_libdeflate = sources/libdeflate/Makefile

$(sources_zlib):
	git submodule update sources/zlib

$(sources_libdeflate):
	git submodule update sources/libdeflate

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

$(sources_xz): sources/$(xz_tar_file)
	cd sources && tar xvJf $(xz_tar_file)

$(sources_bzip2): sources/$(bzip2_tar_file)
	cd sources && tar xvzf $(bzip2_tar_file)

# Build libz.a
sources/zlib/libz.a: $(sources_zlib)
	cd sources/zlib && \
	CFLAGS='-g -O3 -fpic' ./configure && \
	$(MAKE)

# Build libdeflate.a
sources/libdeflate/libdeflate.a: $(sources_libdeflate)
	cd sources/libdeflate && \
	$(MAKE) libdeflate.a CFLAGS='-g -O3 -fpic'

# Build liblzma.a
$(sources_xz)/liblzma.a: $(sources_xz)
	cd $(sources_xz) && \
	./configure --disable-xz --disable-xzdec --disable-lzmadec \
	   --disable-lzmainfo --disable-lzma-links --disable-scripts \
	   --disable-doc --disable-shared CFLAGS='-g -O3 -fpic' && \
	$(MAKE) && \
	cp -av src/liblzma/.libs/liblzma.a ./liblzma.a

# Build libbz2.a
$(sources_bzip2)/libbz2.a: $(sources_bzip2)
	cd $(sources_bzip2) && \
	$(MAKE) CFLAGS='-g -O3 -fpic -D_FILE_OFFSET_BITS=64'

.PHONY: all clean
