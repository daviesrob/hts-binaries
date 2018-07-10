all: wrappers/glibc/libglibc_wrap.a

.c.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) -fpic -c -o $@ $<

clean:
	-rm -f wrappers/glibc/*.o wrappers/glibc/*.a

# Wrappers to deal with glibc versioned symbols
wrappers/glibc/libglibc_wrap.a: wrappers/glibc/glibc_wrap.o wrappers/glibc/glibm_wrap.o
	$(AR) -rc $@ $^

wrappers/glibc/glibc_wrap.o: wrappers/glibc/glibc_wrap.c

wrappers/glibc/glibm_wrap.o: wrappers/glibc/glibm_wrap.c

.PHONY: all clean
