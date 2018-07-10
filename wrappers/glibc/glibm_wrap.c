/*
  signgam (set by lgamma()) is defined by POSIX but not C99.  To avoid
  namespace issues, glibc 2.23 changed signgam to be a weak alias for
  __signgam, and introduced a compatibility version for old binaries that do
  not have __signgam which sets both.
 */

asm(".symver _lgamma_2_2_5, lgamma@GLIBC_2.2.5");
double __wrap_lgamma(double x) {
    return _lgamma_2_2_5(x);
}
