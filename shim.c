#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _POSIX_C_SOURCE
#include <sys/socket.h>

// fake TCP fast open support for libnspr

typedef __uint32_t sae_associd_t;
typedef __uint32_t sae_connid_t;

typedef struct my_sa_endpoints {
    unsigned int     sae_srcif;      /* optional source interface   */
    struct sockaddr *sae_srcaddr;    /* optional source address     */
    socklen_t        sae_srcaddrlen; /* size of source address      */
    struct sockaddr *sae_dstaddr;    /* destination address         */
    socklen_t        sae_dstaddrlen; /* size of destination address */
} my_sa_endpoints_t;

int connectx(int socket, const my_sa_endpoints_t *endpoints,
         sae_associd_t associd, unsigned int flags, const struct iovec *iov,
         unsigned int iovcnt, size_t *len, sae_connid_t *connid) {
    if(iovcnt != 1) {
        puts("connectx with iovcnt != 1");
        errno = EINVAL;
        return -1;
    }
    *len = sendto(socket, iov[0].iov_base, iov[0].iov_len,0,endpoints->sae_dstaddr, endpoints->sae_dstaddrlen);
    return 0;
}

// new secure intrinsics used by llvm

void *__memccpy_chk(void *restrict dst, const void *restrict src, int c, size_t n, int wat) {
    return memccpy(dst,src,c,n);
}

size_t __strlcat_chk(char *b, const char *c, size_t n, int wat) {
    return strlcat(b,c,n);
}

size_t __strlcpy_chk(char *b, const char *c, size_t n, int wat) {
    return strlcpy(b,c,n);
}

// new math intrinsics used by llvm

struct __myfloat2 { float __sinval; float __cosval; };
struct __mydouble2 { double __sinval; double __cosval; };

struct __myfloat2 __sincosf_stret(float x) {
    struct __myfloat2 s;
    s.__sinval = sinf(x);
    s.__cosval = cosf(x);
    return s;
}
struct __mydouble2 __sincos_stret(double x) {
    struct __mydouble2 s;
    s.__sinval = sin(x);
    s.__cosval = cos(x);
    return s;
}

double __exp10(double arg) {
    return pow(10, arg);
}

float __exp10f(float arg) {
    return powf(10, arg);
}

int sandbox_init(const char *profile, uint64_t flags, char **errorbuf) {
	if(errorbuf) *errorbuf = 0;
	return 0;
}
int sandbox_init_with_parameters(const char *profile, uint64_t flags, const char *const parameters[], char **errorbuf) {
	if(errorbuf) *errorbuf = 0;
	return 0;
}
void sandbox_free_error(char *errorbuf) { }
