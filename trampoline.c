#include <stdio.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <limits.h>

#define MY_WEIRD_LC_MAIN 0x28

int callEntryPointOfImage(char *path, int argc, char **argv,char *envp[], char *apple[])
{
    void *handle;
    int (*binary_main)(int binary_argc, char **binary_argv,char *envp[], char *apple[]);
    char *error;
    int err = 0;

    char actualpath[PATH_MAX+1];
    char *real = realpath(path, actualpath);

    handle = dlopen (real, RTLD_LAZY);
    if (!handle) {
        puts (dlerror());
        err = 1;
    }

    uint64_t entryoff = 0;

    /* Find LC_MAIN, entryoff */

    uint32_t count = _dyld_image_count();

    int didFind = 0;

    for(uint32_t i = 0; i < count; i++)
    {
        //Name of image (includes full path)
        const char *dyld = _dyld_get_image_name(i);
        if (!strcmp(dyld, real))
        {
            didFind = 1;
            const struct mach_header *header = (struct mach_header *)_dyld_get_image_header(i);

            if (header->magic == MH_MAGIC_64)
            {
                const struct mach_header_64 *header64 = (struct mach_header_64 *)_dyld_get_image_header(i);

                uint8_t *imageHeaderPtr = (uint8_t*)header64;
                typedef struct load_command load_command;

                imageHeaderPtr += sizeof(struct mach_header_64);
                load_command *command = (load_command*)imageHeaderPtr;

                for(int i = 0; i < header->ncmds > 0; ++i)
                {
                    if(command->cmd == MY_WEIRD_LC_MAIN)
                    {
                        struct entry_point_command ucmd = *(struct entry_point_command*)imageHeaderPtr;

                        entryoff = ucmd.entryoff;
                        didFind = 1;
                        break;
                    }

                    imageHeaderPtr += command->cmdsize;
                    command = (load_command*)imageHeaderPtr;
                }
            }
            else
            {
                const struct mach_header *header = (struct mach_header *)_dyld_get_image_header(i);

                uint8_t *imageHeaderPtr = (uint8_t*)header;
                typedef struct load_command load_command;

                imageHeaderPtr += sizeof(struct mach_header);
                load_command *command = (load_command*)imageHeaderPtr;

                for(int i = 0; i < header->ncmds > 0; ++i)
                {
                    if(command->cmd == MY_WEIRD_LC_MAIN)
                    {
                        struct entry_point_command ucmd = *(struct entry_point_command*)imageHeaderPtr;

                        entryoff = ucmd.entryoff;
                        didFind = 1;
                        break;
                    }

                    imageHeaderPtr += command->cmdsize;
                    command = (load_command*)imageHeaderPtr;
                }
            }

            if (didFind)
            {
                break;
            }
        }
    }

    if (didFind)
    {
        binary_main = dlsym(handle, "_mh_execute_header")+entryoff;
        if ((error = dlerror()) != NULL)  {
            puts(error);
            err = 1;
        }

        if (err == 0)
        {
            int i = (*binary_main)(argc, argv,envp,apple);
            _exit(i);
        } else {
            abort();
        }
    }
    return 1;
}
int main(int argc, char *argv[], char *envp[], char *apple[]) {
    int sl = strlen(argv[0]);
    char *argv0new = malloc(sl+6);
    strcpy(argv0new,argv[0]);
    strcat(argv0new,"_real");
    return callEntryPointOfImage(argv0new,argc,argv,envp,apple);
}
