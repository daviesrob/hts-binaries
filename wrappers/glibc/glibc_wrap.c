/*  glibc_wrap.c -- Wrappers to make htslib work with old glibc versions

    Copyright (c) 2018 Genome Research Ltd.

    Author: Rob Davies <rmd@sanger.ac.uk>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.  */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <sys/select.h>
#include <execinfo.h>
#ifdef NDEBUG
#undef NDEBUG // We will have assertions
#endif
#include <assert.h>

/*
  A memcpy() versioned symbol was added in glibc 2.14 to fix programs that
  broke when the order in which bytes were copied changed (in glibc 2.13).
  The "older" memcpy() is actually just an alias for memmove().
*/
void *__wrap_memcpy(void *dest, const void *src, size_t n) {
    return memmove(dest, src, n);
}

/*
  scanf() and friends were changed in glibc 2.7 to support the C99 'm' modifier.
  It also gets redirected to __isoc99_scanf() by stdio.h (similarly for
  fscanf(), sscanf() etc.)
 */
extern int _vscanf_2_2_5(const char *format, va_list ap);
extern int _vsscanf_2_2_5(const char *str, const char *format, va_list ap);
extern int _vfscanf_2_2_5(FILE *stream, const char *format, va_list ap);
asm(".symver _vscanf_2_2_5, vscanf@GLIBC_2.2.5");
asm(".symver _vsscanf_2_2_5, vsscanf@GLIBC_2.2.5");
asm(".symver _vfscanf_2_2_5, vfscanf@GLIBC_2.2.5");
int __wrap_scanf(const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vscanf_2_2_5(format, args);
    va_end(args);
    return res;
}
int __wrap___isoc99_scanf(const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vscanf_2_2_5(format, args);
    va_end(args);
    return res;
}
int __wrap_sscanf(const char *str, const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vsscanf_2_2_5(str, format, args);
    va_end(args);
    return res;
}
int __wrap___isoc99_sscanf(const char *str, const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vsscanf_2_2_5(str, format, args);
    va_end(args);
    return res;
}
int __wrap_fscanf(FILE *stream, const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vfscanf_2_2_5(stream, format, args);
    va_end(args);
    return res;
}
int __wrap___isoc99_fscanf(FILE *stream, const char *format, ...) {
    va_list args;
    int res;
    va_start(args, format);
    res = _vfscanf_2_2_5(stream, format, args);
    va_end(args);
    return res;
}

/*
  __fdelt_chk() appeared as part of the stack protection in glibc 2.15.
  It detects accesses beyond the end of an FD_SET.
 */

long int __wrap___fdelt_chk(long int d) {
    assert(d >= 0 && d < FD_SETSIZE);
    return d / __NFDBITS;
}

/*
  __stack_chk_fail() appeared as part of the stack protection in glibc 2.4.
  It's called when stack smashing has been detected.
 */

void __wrap___stack_chk_fail(void) {
    void *bt[32];
    size_t s;
    fprintf(stderr, "stack smashing detected\n");
    s = backtrace(bt, sizeof(bt)/sizeof(bt[0]));
    backtrace_symbols_fd(bt, s, fileno(stderr));
    abort();
}

/*
  __vasprintf_chk appeared as part of the stack protection in glibc 2.8
*/
extern int _vasprintf_2_2_5(char **strp, const char *fmt, va_list ap);
asm(".symver _vasprintf_2_2_5, vasprintf@GLIBC_2.2.5");
int __wrap___vasprintf_chk(char **strp, int flags_ignored, const char *fmt,
                           va_list args) {
    return _vasprintf_2_2_5(strp, fmt, args);
}
