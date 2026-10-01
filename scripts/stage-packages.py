#!/usr/bin/env python3
"""Convert cached ARM64 application/firmware payloads and local kernel into pacman inputs."""
import argparse, hashlib, pathlib, shutil, subprocess, tarfile, re
p=argparse.ArgumentParser()
p.add_argument('--cache',type=pathlib.Path,default=pathlib.Path('../ubuntu-oneplus-aston/build'))
p.add_argument('--kernel',type=pathlib.Path)
p.add_argument('--only', choices=['firmware-oneplus-aston','localsend-aston','flclash-aston','linux-oneplus-aston'])
a=p.parse_args()
project=pathlib.Path(__file__).resolve().parents[1]
cache=a.cache.resolve(); kernel=(a.kernel or (project/'build/kernel-7.2-arch' if (project/'build/kernel-7.2-arch').exists() else cache/'kernel-7.2')).resolve()
items=[('firmware-oneplus-aston','firmware-oneplus-aston-a15.deb'),('localsend-aston','LocalSend.deb'),('flclash-aston','FlClash.deb'),('linux-oneplus-aston',None)]
for name,deb in items:
 if a.only and name != a.only: continue
 stage=project/'build'/'package-stage'/name
 if stage.exists(): shutil.rmtree(stage)
 stage.mkdir(parents=True)
 if deb:
  subprocess.run(['dpkg-deb','-x',str(cache/deb),str(stage)],check=True)
  # Firmware deb postinst is replaced by Arch services and firmware search paths.
  for child in list(stage.iterdir()):
   if child.name != 'usr':
    shutil.rmtree(child) if child.is_dir() else child.unlink()
  if name == 'firmware-oneplus-aston':
   bmi = project/'firmware/bmi260'
   if hashlib.sha256((bmi/'bmi260-init-data.fw').read_bytes()).hexdigest() != 'cf0527e2a34aaf3acfdf5ca539cfb47c2381693d064b49d1479ebcfab0cca377':
    raise ValueError('Unexpected BMI260 firmware checksum')
   shutil.copy2(bmi/'bmi260-init-data.fw',stage/'usr/lib/firmware/bmi260-init-data.fw')
   license_dir = stage/'usr/share/licenses/firmware-oneplus-aston'
   license_dir.mkdir(parents=True,exist_ok=True)
   shutil.copy2(bmi/'LICENSE.bmi260',license_dir/'LICENSE.bmi260')
   for item in ['regulatory.db','regulatory.db.p7s']:
    (stage/'usr/lib/firmware'/item).unlink(missing_ok=True)
 else:
  (stage/'usr/lib').mkdir(parents=True)
  with tarfile.open(kernel/'modules-7.2.tar.gz') as archive:
   archive.extractall(stage,filter='data')
  if (stage/'lib/modules').exists():
   shutil.move(str(stage/'lib/modules'),str(stage/'usr/lib/modules'))
   shutil.rmtree(stage/'lib')
  (stage/'boot').mkdir()
  shutil.copy2(kernel/'Image_w_dtb.gz',stage/'boot/Image-aston.gz-dtb')
 output=project/'packages'/name/'payload.tar.gz'
 with tarfile.open(output,'w:gz') as archive:
  for child in stage.iterdir(): archive.add(child,arcname=child.name)
 digest=hashlib.sha256(output.read_bytes()).hexdigest()
 pkg=output.parent/'PKGBUILD'
 pkg.write_text(re.sub(r"sha256sums=\('[0-9a-f]+'\)",f"sha256sums=('{digest}')",pkg.read_text()))
 print(name,digest)
