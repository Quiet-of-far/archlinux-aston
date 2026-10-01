#!/usr/bin/env python3
"""Sample SM8550 INTF1 counters without writing any hardware register."""
import mmap
import os
import struct
import time

# DPU register base plus INTF1 catalog offset. Open and mmap read-only.
fd = os.open('/dev/mem', os.O_RDONLY | os.O_SYNC)
try:
    with mmap.mmap(fd, 4096, flags=mmap.MAP_SHARED,
                   prot=mmap.PROT_READ, offset=0xAE36000) as regs:
        def read(offset):
            return struct.unpack_from('<I', regs, offset)[0]

        for offset in (0x60, 0x280, 0x284, 0x288, 0x28C, 0x294, 0x29C):
            print(f'config {offset:#05x}: {read(offset):#010x}', flush=True)
        start = time.monotonic()
        first_te = read(0x298) >> 16
        first_done = read(0xAC)
        time.sleep(3)
        elapsed = time.monotonic() - start
        te = ((read(0x298) >> 16) - first_te) & 0xFFFF
        done = (read(0xAC) - first_done) & 0xFFFFFFFF
        print(f'{elapsed:.4f}s: TE {te} ({te/elapsed:.3f} Hz), '
              f'completed {done} ({done/elapsed:.3f} Hz)')
finally:
    os.close(fd)
