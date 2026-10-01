#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 MODEL.gguf [llama-bench options]" >&2
    exit 2
fi
ace3_model=$1
shift
ace3_runtime=${ACE3_LLAMA_ROOT:-/home/ace3/llama-htp}
export LD_LIBRARY_PATH="$ace3_runtime/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ADSP_LIBRARY_PATH="$ace3_runtime/lib;/usr/lib/rfsa/adsp"
export ACE3_HTP_STRICT=${ACE3_HTP_STRICT:-0}
export ACE3_HTP_HOST_WINDOW_MB=1536
export ACE3_HTP_HOST_LARGE_MB=${ACE3_HTP_HOST_LARGE_MB:-64}
export GGML_HEXAGON_DEVICES=HTP0
export GGML_HEXAGON_OPPOLL=1
export GGML_HEXAGON_VMEM=1536
export GGML_HEXAGON_MBUF=128
export GGML_HEXAGON_OPBATCH=64
ulimit -c 0
exec timeout --signal=TERM --kill-after=10 300 "$ace3_runtime/bin/llama-bench" \
    -m "$ace3_model" -dev HTP0 -ngl 99 -p 64 -n 32 -b 64 -ub 64 \
    -t 4 -fa on -r 2 -o json --progress "$@"
