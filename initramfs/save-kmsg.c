#define _GNU_SOURCE
#include <fcntl.h>
#include <poll.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
static time_t monotonic(void) {struct timespec t; clock_gettime(CLOCK_MONOTONIC,&t); return t.tv_sec;}
int main(int argc, char **argv) {
 if (argc != 2) return 2;
 int out=open(argv[1], O_WRONLY|O_CREAT|O_TRUNC|O_DSYNC,0600);
 int in=open("/dev/kmsg",O_RDONLY|O_NONBLOCK);
 if(out<0||in<0){perror("early kmsg");return 1;}
 struct pollfd p={.fd=in,.events=POLLIN};
 char b[16384];time_t end=monotonic()+120;
 while(monotonic()<end) {
  if(poll(&p,1,500)<=0) continue;
  ssize_t n=read(in,b,sizeof(b));
  if(n<0 && (errno==EAGAIN || errno==EPIPE)) continue;
  if(n<=0) break;
  for(ssize_t off=0;off<n;) {ssize_t w=write(out,b+off,n-off);if(w<=0)return 1;off+=w;}
 }
 fsync(out);close(out);close(in);return 0;
}
