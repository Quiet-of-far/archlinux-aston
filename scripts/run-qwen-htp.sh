#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 'prompt' [llama-completion options]" >&2
    exit 2
fi
ace3_prompt=$1
shift
# Match this model's GGUF template explicitly: the completion frontend does
# not forward --reasoning/template kwargs to common_chat_format_single.
printf -v ace3_formatted_prompt '<|im_start|>user\n%s<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n' "$ace3_prompt"
ace3_runtime=${ACE3_LLAMA_ROOT:-/home/ace3/llama-htp}
export LD_LIBRARY_PATH="$ace3_runtime/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export ADSP_LIBRARY_PATH="$ace3_runtime/lib;/usr/lib/rfsa/adsp"
export ACE3_HTP_STRICT=0
export ACE3_HTP_HOST_WINDOW_MB=1536
export ACE3_HTP_HOST_LARGE_MB=256
export GGML_HEXAGON_DEVICES=HTP0
export GGML_HEXAGON_OPPOLL=1
export GGML_HEXAGON_VMEM=1536
export GGML_HEXAGON_MBUF=128
export GGML_HEXAGON_OPBATCH=64
ulimit -c 0
exec "$ace3_runtime/bin/llama-completion" \
    -m /home/ace3/Qwen3.5-9B-from-Q3_K_M-Q4_0.gguf --device HTP0 -ngl 99 \
    -c 2048 -b 64 -ub 64 -t 4 -fa on --no-warmup \
    -no-cnv -n 256 -p "$ace3_formatted_prompt" "$@"
