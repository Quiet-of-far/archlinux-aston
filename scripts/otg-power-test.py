#!/usr/bin/env python3
"""Bounded diagnostic, requiring Aston's temporary otg_power_test attribute."""
from pathlib import Path
import subprocess,time
base=Path('/sys/class/power_supply/qcom-battmgr-usb')
battery=Path('/sys/class/power_supply/bq28z610-0')
switch=base/'oplus/otg_power_test'
role=Path('/sys/class/usb_role/a600000.usb-role-switch/role')
def number(path):
    return int(path.read_text())
try:
    if number(base/'online') or number(base/'oplus/typec_mode') != 1:
        raise RuntimeError('OTG attachment without external power required')
    role.write_text('host\n')
    time.sleep(1)
    switch.write_text('1\n')
    print('VBUS test enabled, maximum 30 seconds',flush=True)
    end=time.monotonic()+27
    last=None
    while time.monotonic()<end:
        current=number(battery/'current_now')
        temp=number(battery/'temp')
        capacity=number(battery/'capacity')
        if abs(current)>1700000 or not 0<=temp<=400 or capacity<15:
            raise RuntimeError(f'Battery guard: {current=} {temp=} {capacity=}')
        if number(base/'oplus/typec_mode') != 1:
            raise RuntimeError('OTG detached or role changed')
        devices=subprocess.check_output(['lsusb'],text=True)
        if devices!=last:
            print(devices,flush=True)
            last=devices
        time.sleep(.5)
finally:
    switch.write_text('0\n')
    print('VBUS test disabled',flush=True)
