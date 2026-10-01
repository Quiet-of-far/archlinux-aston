/* Regression check: bad map lengths and descriptors from a stopped CDSP.
 * Run as root only on an idle test device. Does not submit DSP workloads. */
#include <errno.h>
#include <fcntl.h>
#include <linux/dma-heap.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <unistd.h>
#include "fastrpc.h"

static int map_errno(int rpc, int buffer)
{
    struct fastrpc_mem_map map = {.fd = buffer, .length = 8192};
    int ret = ioctl(rpc, FASTRPC_IOCTL_MEM_MAP, &map);
    return ret < 0 ? errno : 0;
}

static int state(const char *path, const char *value)
{
    int fd = open(path, O_WRONLY), ret;
    if (fd < 0) return -1;
    ret = write(fd, value, strlen(value));
    close(fd);
    return ret == (int)strlen(value) ? 0 : -1;
}

int main(int argc, char **argv)
{
    struct dma_heap_allocation_data alloc = {.len = 4096, .fd_flags = O_RDWR | O_CLOEXEC};
    int heap = open("/dev/dma_heap/system", O_RDWR);
    int old = open("/dev/fastrpc-cdsp", O_RDWR), fresh = -1, failed = 0;
    if (heap < 0 || old < 0 || ioctl(heap, DMA_HEAP_IOCTL_ALLOC, &alloc)) {
        perror("open/allocate"); return 1;
    }
    for (int i = 0; i < 32; ++i) {
        int err = map_errno(old, alloc.fd);
        if (err != EINVAL) { printf("bad length iteration %d: errno=%d\n", i, err); return 1; }
    }
    void *memory = mmap(NULL, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, alloc.fd, 0);
    if (memory == MAP_FAILED) { perror("mmap after rejected maps"); return 1; }
    memset(memory, 0x5a, 4096);
    printf("32 rejected oversized mappings; DMA buffer remains accessible\n");
    if (argc == 2) {
        if (state(argv[1], "stop")) { perror("stop CDSP"); return 1; }
        int err = map_errno(old, alloc.fd);
        printf("old fd while stopped: errno=%d (expected %d)\n", err, EPIPE);
        failed |= err != EPIPE;
        if (state(argv[1], "start")) { perror("start CDSP"); return 1; }
        for (int i = 0; i < 100 && fresh < 0; ++i) {
            usleep(100000);
            fresh = open("/dev/fastrpc-cdsp", O_RDWR);
        }
        err = map_errno(old, alloc.fd);
        printf("old fd after restart: errno=%d (expected %d)\n", err, EPIPE);
        failed |= err != EPIPE;
        if (fresh < 0) { perror("fresh fd after restart"); failed = 1; }
        else {
            err = map_errno(fresh, alloc.fd);
            printf("fresh fd rejects bad length: errno=%d (expected %d)\n", err, EINVAL);
            failed |= err != EINVAL;
            close(fresh);
        }
    }
    munmap(memory, 4096);
    close(alloc.fd); close(old); close(heap);
    return failed;
}
