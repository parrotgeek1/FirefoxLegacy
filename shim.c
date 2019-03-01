#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _POSIX_C_SOURCE 200809L
#include <sys/socket.h>
#include <dlfcn.h>
#include <unistd.h>
#include <spawn.h>

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

typedef int (pr_realconnectx) (int, const my_sa_endpoints_t *, sae_associd_t, unsigned int, const struct iovec *, unsigned int, size_t *, sae_connid_t *);
typedef pr_realconnectx* pt_pr_realconnectx;
static pt_pr_realconnectx realconnectx = NULL;

__attribute__((constructor)) static void initConnectxShim(){
    void *handle = dlopen ("/usr/lib/libSystem.B.dylib", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }
    realconnectx = (pt_pr_realconnectx) dlsym(handle, "connectx");
}

int connectx(int socket, const my_sa_endpoints_t *endpoints,sae_associd_t associd, unsigned int flags, const struct iovec *iov,unsigned int iovcnt, size_t *len, sae_connid_t *connid) {
    if(realconnectx) return realconnectx(socket,endpoints,associd,flags,iov,iovcnt,len,connid);
    if(iovcnt != 1) {
        fprintf(stderr,"unimplemented shim connectx with iovcnt %u != 1\n",iovcnt);
        abort();
    }
    *len = sendto(socket, iov[0].iov_base, iov[0].iov_len,0,endpoints->sae_dstaddr, endpoints->sae_dstaddrlen);
    return 0;
}

// new secure intrinsics used by llvm
// https://github.com/unofficial-opensource-apple/Libc/tree/master/secure

static void my__chk_overlap (const void *a, size_t an, const void *b, size_t bn)
{
    if (((uintptr_t)a) <= ((uintptr_t)b)+bn && ((uintptr_t)b) <= ((uintptr_t)a)+an)
        abort();
}

void *
__memccpy_chk (void *dest, const void *src, int c, size_t len, size_t dstlen)
{
    void *retval;

    if (__builtin_expect (dstlen < len, 0))
        abort ();

    /* retval is NULL if len was copied, otherwise retval is the
     * byte *after* the last one written.
     */
    retval = memccpy (dest, src, c, len);

    if (retval != NULL) {
        len = (uintptr_t)retval - (uintptr_t)dest;
    }

    my__chk_overlap(dest, len, src, len);

    return retval;
}

size_t
__strlcat_chk (char *restrict dest, char *restrict src,
               size_t len, size_t dstlen)
{
    size_t initial_srclen;
    size_t initial_dstlen;

    if (__builtin_expect (dstlen < len, 0))
        abort ();

    initial_srclen = strlen(src);
    initial_dstlen = strnlen(dest, len);

    if (initial_dstlen == len)
        return len+initial_srclen;

    if (initial_srclen < len - initial_dstlen) {
        my__chk_overlap(dest, initial_srclen + initial_dstlen + 1, src, initial_srclen + 1);
        memcpy(dest+initial_dstlen, src, initial_srclen + 1);
    } else {
        my__chk_overlap(dest, initial_srclen + initial_dstlen + 1, src, len - initial_dstlen - 1);
        memcpy(dest+initial_dstlen, src, len - initial_dstlen - 1);
        dest[len-1] = '\0';
    }

    return initial_srclen + initial_dstlen;
}

size_t
__strlcpy_chk (char *restrict dest, char *restrict src,
               size_t len, size_t dstlen)
{
    size_t retval;
    if (__builtin_expect (dstlen < len, 0))
        abort ();

    retval = strlcpy (dest, src, len);

    if (retval < len)
        len = retval + 1;

    my__chk_overlap(dest, len, src, len);

    return retval;
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

int sandbox_init_with_parameters(const char *profile, uint64_t flags, const char *const parameters[], char **errorbuf) {
	if(errorbuf) *errorbuf = 0;
	return 0;
}
void sandbox_free_error(char *errorbuf) { }

// kernel panic workaround
int posix_spawnattr_setflags(posix_spawnattr_t *attr, short flags) {
    puts("XXXXX posix_spawnattr_setflags");
    return 0;
}
