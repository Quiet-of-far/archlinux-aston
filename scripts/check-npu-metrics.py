#!/usr/bin/env python3
"""Exercise the public libqcnpuperf API; a failure is not reported as zero load."""
import ctypes as C,sys,time,os
lib=C.CDLL(os.environ.get('QCNPUPERF_LIBRARY','libqcnpuperf.so.1'))
lib.qcom_dsp_open.argtypes=[C.c_int];lib.qcom_dsp_open.restype=C.c_void_p
lib.qcom_dsp_close.argtypes=[C.c_void_p]
lib.qcom_dsp_get_prof_data.argtypes=[C.c_void_p,C.POINTER(C.c_int)]
lib.qcom_dsp_get_prof_data.restype=C.c_void_p
lib.qcom_dsp_prof_get_q6_arch_version.argtypes=[C.c_void_p]
lib.qcom_dsp_prof_get_q6_arch_version.restype=C.c_uint
for name in ['q6_utilization','hvx_utilization','hmx_utilization','q6_clock']:
 fn=getattr(lib,'qcom_dsp_prof_get_'+name);fn.argtypes=[C.c_void_p]
 fn.restype=C.c_uint if name=='q6_clock' else C.c_float
ctx=lib.qcom_dsp_open(3)
if not ctx:
 print('CDSP metrics session failed to open',file=sys.stderr);sys.exit(1)
try:
 raw_arch=lib.qcom_dsp_prof_get_q6_arch_version(ctx)
 print(f'Hexagon architecture code: 0x{raw_arch:x} (v{raw_arch:x})',flush=True)
 for i in range(3):
  count=C.c_int();data=lib.qcom_dsp_get_prof_data(ctx,C.byref(count))
  if not data:
   raise RuntimeError('DSP metrics query failed')
  print('Metrics:',count.value,{name:getattr(lib,'qcom_dsp_prof_get_'+name)(data)
   for name in ['q6_utilization','hvx_utilization','hmx_utilization','q6_clock']},flush=True)
  time.sleep(1)
finally:
 lib.qcom_dsp_close(ctx)
