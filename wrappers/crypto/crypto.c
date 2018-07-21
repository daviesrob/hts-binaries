
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
