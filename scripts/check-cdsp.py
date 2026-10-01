#!/usr/bin/env python3
"""Query CDSP capabilities over FastRPC; this is not an inference benchmark."""
import fcntl
import os
import struct

attributes = {1: 'Unsigned PD', 2: 'HVX 64B units', 3: 'HVX 128B units',
              4: 'VTCM page bytes', 5: 'VTCM pages', 6: 'Architecture version',
              7: 'HMX depth', 8: 'HMX spatial'}
fd = os.open('/dev/fastrpc-cdsp', os.O_RDWR)
try:
    for index, label in attributes.items():
        request = bytearray(struct.pack('7I', 0, index, 0, 0, 0, 0, 0))
        fcntl.ioctl(fd, 0xc01c520d, request, True)
        value = struct.unpack('7I', request)[2]
        print(f'{label}: {value} (0x{value:x})')
finally:
    os.close(fd)
