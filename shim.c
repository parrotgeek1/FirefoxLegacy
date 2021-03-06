#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define _POSIX_C_SOURCE 200809L
#include <sys/socket.h>
#undef _POSIX_C_SOURCE
#include <dlfcn.h>
#include <unistd.h>
#include <spawn.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/utsname.h>

static int lion = 0;

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

typedef int (pr_realposix_spawn) (pid_t *restrict, const char *restrict,const posix_spawn_file_actions_t *,const posix_spawnattr_t *restrict, char *const [restrict],char *const [restrict]);
typedef pr_realposix_spawn* pt_pr_realposix_spawn;
static pt_pr_realposix_spawn realposix_spawn = NULL;
static pt_pr_realposix_spawn realposix_spawnp = NULL;
typedef int (pr_realsandbox_init_with_parameters) (const char *, uint64_t, const char *const[], char **);
typedef pr_realsandbox_init_with_parameters* pt_pr_realsandbox_init_with_parameters;
static pt_pr_realsandbox_init_with_parameters realsandbox_init_with_parameters = NULL;

__attribute__((constructor)) static void initCShim(){
    void *handle = dlopen ("/usr/lib/libSystem.B.dylib", RTLD_NOW);
    if (!handle) {
        puts (dlerror());
        abort();
    }
    realconnectx = (pt_pr_realconnectx) dlsym(handle, "connectx");
    realposix_spawn = (pt_pr_realposix_spawn) dlsym(handle, "posix_spawn");
    if(!realposix_spawn) {
        puts("No posix_spawn");
        abort();
    }
    realposix_spawnp = (pt_pr_realposix_spawn) dlsym(handle, "posix_spawnp");
    if(!realposix_spawnp) {
        puts("No posix_spawnp");
        abort();
    }
    struct utsname buffer;
    if (uname(&buffer) != 0) {
        puts("uname failed");
        abort();
    }

    if(strlen(buffer.release) >= 3) {
        if(buffer.release[0]=='1' && buffer.release[1]=='1' && buffer.release[2]=='.') {
            lion = 1;
        }
    }

    if(realconnectx) {
        // 10.9+
        realsandbox_init_with_parameters = (pt_pr_realsandbox_init_with_parameters) dlsym(handle, "sandbox_init_with_parameters");
        if(!realsandbox_init_with_parameters) {
            fprintf(stderr,"weird, can't find sandbox_init_with_parameters");
            abort();
        }
    }
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
    if(realsandbox_init_with_parameters) return realsandbox_init_with_parameters(profile, flags, parameters, errorbuf);
    if(errorbuf) *errorbuf = 0;
    return 0;
}

// from old Mozilla code
static void SetAllFDsToCloseOnExec() {
    const char fd_dir[] = "/dev/fd";
    DIR *dir = opendir(fd_dir);
    if (NULL == dir) {
        fprintf(stderr,"Unable to open %s\n", fd_dir);
        return;
    }

    struct dirent *ent;
    while ((ent = readdir(dir))) {
        // Skip . and .. entries.
        if (ent->d_name[0] == '.')
            continue;
        int i = atoi(ent->d_name);
        // We don't close stdin, stdout or stderr.
        if (i <= STDERR_FILENO)
            continue;

        int flags = fcntl(i, F_GETFD);
        if ((flags == -1) || (fcntl(i, F_SETFD, flags | FD_CLOEXEC) == -1)) {
            fprintf(stderr,"fcntl failure.\n");
        }
    }
}

// kernel panic workaround posix_spawnattr_setflags cloexec simply does not work in Lion at all
int
posix_spawn(pid_t *restrict pid, const char *restrict path,
            const posix_spawn_file_actions_t *file_actions,
            const posix_spawnattr_t *restrict attrp, char *const argv[restrict],
            char *const envp[restrict]){
    if(lion && attrp) {
        short flags = 0;
        if(posix_spawnattr_getflags(attrp,&flags) == 0) {
            if((flags & POSIX_SPAWN_CLOEXEC_DEFAULT) == POSIX_SPAWN_CLOEXEC_DEFAULT) {
                flags &= ~POSIX_SPAWN_CLOEXEC_DEFAULT;
                if(posix_spawnattr_setflags((posix_spawnattr_t *)attrp,flags) != 0) {
                    abort();
                }
                SetAllFDsToCloseOnExec();
            }
        }
    }
    return realposix_spawn(pid,path,file_actions,attrp,argv,envp);
}

int
posix_spawnp(pid_t *restrict pid, const char *restrict file,
             const posix_spawn_file_actions_t *file_actions,
             const posix_spawnattr_t *restrict attrp, char *const argv[restrict],
             char *const envp[restrict]){
    if(lion && attrp) {
        short flags = 0;
        if(posix_spawnattr_getflags(attrp,&flags) == 0) {
            if((flags & POSIX_SPAWN_CLOEXEC_DEFAULT) == POSIX_SPAWN_CLOEXEC_DEFAULT) {
                flags &= ~POSIX_SPAWN_CLOEXEC_DEFAULT;
                if(posix_spawnattr_setflags((posix_spawnattr_t *)attrp,flags) != 0) {
                    abort();
                }
                SetAllFDsToCloseOnExec();
            }
        }
    }
    return realposix_spawnp(pid,file,file_actions,attrp,argv,envp);
}
