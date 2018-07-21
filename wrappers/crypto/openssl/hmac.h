#ifndef FAKE_OPENSSL_HMAC_H
#define FAKE_OPENSSL_HMAC_H

#define EVP_MAX_MD_SIZE 64  /* Enough for SHA512 */

int EVP_sha1(void);

unsigned char *HMAC(int algo, const void *key, int key_len,
                    const unsigned char *d, size_t n, unsigned char *md,
                    unsigned int *md_len);

#endif /* FAKE_OPENSSL_HMAC_H */
