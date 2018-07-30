/*  crypto.c -- Interface nettle's hmac functions to htslib

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
  We currently only use libcrypto for S3 authorization, which uses the
  functions HMAC() and EVP_sha1().  This allows us to use the nettle
  equivalent, avoiding the need for openssl.

  The interface isn't quite the openssl one, but gets the job done.

  TODO: Get htslib to support alternate crypto libs.
 */

#include <nettle/hmac.h>

#define HMAC_SHA1 1

int EVP_sha1(void) {
    return HMAC_SHA1;
}

unsigned char *HMAC(int algo, const void *key, int key_len,
                    const unsigned char *d, size_t n, unsigned char *md,
                    unsigned int *md_len) {
    switch (algo) {
    case HMAC_SHA1: {
        struct hmac_sha1_ctx ctx = { 0 };
        hmac_sha1_set_key(&ctx, key_len, key);
        hmac_sha1_update(&ctx, n, d);
        hmac_sha1_digest(&ctx, SHA1_DIGEST_SIZE, md);
        *md_len = SHA1_DIGEST_SIZE;
        break;
    }
    default:
        return NULL;
    }
    return md;
}
