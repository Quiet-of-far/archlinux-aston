#!/usr/bin/env python3
import subprocess,sys,shlex,os
from pathlib import Path
p=Path(__file__).resolve().parents[1]
user=sys.argv[1];cmd=sys.argv[2]
hosts=p/'secrets'/('arch-hosts' if user=='ace3' else 'ubuntu-hosts')
host=os.environ.get('ACE3_SSH_HOST','192.168.77.2')
args=['ssh','-o','IPQoS=none','-o','ConnectTimeout=5','-o','ServerAliveInterval=3','-o','ServerAliveCountMax=3','-o','StrictHostKeyChecking=yes','-o','HostKeyAlias=192.168.77.2','-o','UserKnownHostsFile='+str(hosts),'-i',str(p/'secrets/ace3_ssh_ed25519'),user+'@'+host,'sudo -S -p "" bash -c '+shlex.quote(cmd)]
sys.exit(subprocess.run(args,input=(p/'secrets/login.password').read_bytes().strip()+b'\n').returncode)
