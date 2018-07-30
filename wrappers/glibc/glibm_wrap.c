/*  glibm_wrap.c -- Wrappers to make htslib work with old glibc versions

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

/*
  signgam (set by lgamma()) is defined by POSIX but not C99.  To avoid
  namespace issues, glibc 2.23 changed signgam to be a weak alias for
  __signgam, and introduced a compatibility version for old binaries that do
  not have __signgam which sets both.
 */
extern double _lgamma_2_2_5(double x);
asm(".symver _lgamma_2_2_5, lgamma@GLIBC_2.2.5");
double __wrap_lgamma(double x) {
    return _lgamma_2_2_5(x);
}
