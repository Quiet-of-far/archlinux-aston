#!/usr/bin/env python3
"""Read-only NFC inventory, optional controller enable and RF polling test."""
import argparse
import errno
import socket
import struct
import time

p = argparse.ArgumentParser()
p.add_argument('--up', action='store_true')
p.add_argument('--poll', action='store_true')
p.add_argument('--stop', action='store_true')
p.add_argument('--down', action='store_true')
p.add_argument('--watch', type=int, default=0, help='Monitor detected targets for this many seconds')
a = p.parse_args()
s = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, 16)
s.bind((0, 0))
s.settimeout(12)
seq = 0

def attr(kind, data):
    data = struct.pack('HH', len(data) + 4, kind) + data
    return data + b'\0' * (-len(data) % 4)

def attrs(data):
    result = {}
    while len(data) >= 4:
        length, kind = struct.unpack_from('HH', data)
        if length < 4 or length > len(data):
            raise ValueError('Invalid netlink attribute')
        result[kind & 0x3fff] = data[4:length]
        data = data[(length + 3) & ~3:]
    return result

def request(family, command, payload=b'', dump=False):
    global seq
    seq += 1
    flags = 1 | (0x300 if dump else 4)
    body = struct.pack('BBH', command, 1, 0) + payload
    s.send(struct.pack('IHHII', 16 + len(body), family, flags, seq, 0) + body)
    replies = []
    while True:
        data = s.recv(65536)
        while len(data) >= 16:
            length, kind, flags, number, pid = struct.unpack_from('IHHII', data)
            body = data[16:length]
            data = data[(length + 3) & ~3:]
            if number != seq:
                continue
            if kind == 2:
                error = struct.unpack_from('i', body)[0]
                if error:
                    raise OSError(-error, errno.errorcode.get(-error, 'netlink error'))
                return replies
            if kind == 3:
                return replies
            replies.append(attrs(body[4:]))

family = struct.unpack('H', request(16, 3, attr(2, b'nfc\0'))[0][1])[0]
index = attr(1, struct.pack('I', 0))
if a.up:
    request(family, 2, index)
    print('Controller enabled')
if a.poll:
    request(family, 6, index + attr(3, struct.pack('I', 0xfe)))
    print('RF polling started')
if a.stop:
    request(family, 7, index)
    print('RF polling stopped')
if a.down:
    request(family, 3, index)
    print('Controller disabled')
for item in request(family, 1, dump=True):
    print('Device:', item.get(2, b'').rstrip(b'\0').decode(),
          'powered:', item.get(12, b'\0').hex(),
          'protocols:', item.get(3, b'').hex())
if a.poll or a.watch:
    targets = request(family, 8, index, dump=True)
    print('Targets detected:', len(targets))
    until = time.monotonic() + a.watch
    while time.monotonic() < until:
        time.sleep(1)
        targets = request(family, 8, index, dump=True)
        if targets:
            print('Targets detected:', len(targets),
                  'protocols:', [t.get(3, b'').hex() for t in targets], flush=True)
