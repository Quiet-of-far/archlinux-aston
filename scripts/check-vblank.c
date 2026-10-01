/* Measure DRM frame synchronization without changing the display mode. */
#include <fcntl.h>
#include <stdio.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <libdrm/drm.h>

int main(void)
{
    int fd = open("/dev/dri/card0", O_RDWR);
    double first = 0, last = 0;
    unsigned first_seq = 0, last_seq = 0;
    if (fd < 0) { perror("open"); return 1; }
    for (int i = 0; i <= 120; ++i) {
        union drm_wait_vblank vb = {0};
        vb.request.type = _DRM_VBLANK_RELATIVE;
        vb.request.sequence = 1;
        if (ioctl(fd, DRM_IOCTL_WAIT_VBLANK, &vb)) {
            perror("WAIT_VBLANK"); close(fd); return 1;
        }
        last = vb.reply.tval_sec + vb.reply.tval_usec / 1000000.0;
        last_seq = vb.reply.sequence;
        if (i == 0) { first = last; first_seq = last_seq; }
    }
    printf("%u frames in %.6f s: %.3f Hz\n",
           last_seq - first_seq, last - first,
           (last_seq - first_seq) / (last - first));
    close(fd);
    return 0;
}
