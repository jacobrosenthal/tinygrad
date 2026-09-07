#!/bin/bash
# Long-context decode with attention decode variants: ATTN_QT=4 (2 WGs/CU) and chunk sizes 128/512, each = the same 6 prompt lengths
# as longctx_sweep.sh (ATTN_QT / AMD_ATTN_MQ_CH are in the LLM cache key? ATTN_QT yes; CH not -> LLM_CACHE=0 for the CH legs).
#   bash longctx_variants.sh
K=/home/jacob/z/tinygrad/sweeps/chestnut-usb3-20260830/usb4-kfd-20260906
for v in "qt4|ATTN_QT=4|1" "qt8-ch512|ATTN_QT=8 AMD_ATTN_MQ_CH=512|0" "qt4-ch512|ATTN_QT=4 AMD_ATTN_MQ_CH=512|0" "qt8-ch128|ATTN_QT=8 AMD_ATTN_MQ_CH=128|0"; do
  IFS='|' read -r name envs cache <<< "$v"; echo "=== $name ($envs)"
  env $envs LLM_CACHE=$cache bash $K/longctx/longctx_sweep.sh 2>&1 | grep -E "words=|did not|DONE" | sed "s/^/$name: /"
done
