#!/bin/bash
set -e

# Простое логирование через вывод (systemd сам перехватывает вывод)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Запуск llama-server-wrapper ==="

# Определение GPU
GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -1 | tr '[:upper:]' '[:lower:]')
GPU_CC=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -1 | sed 's/\.//')

echo "GPU обнаружен: $GPU_NAME (Compute Capability: $GPU_CC)"

# Автоматический подбор параметров
case "$GPU_NAME" in
  *h200*|*hopper200*)
    GPU_LAYERS=49
    CTX_SIZE=32768
    ;;
  *h100*|*hopper100*)
    GPU_LAYERS=49
    CTX_SIZE=32768
    ;;
  *rtx4090*|*4090*)
    GPU_LAYERS=45
    CTX_SIZE=32768
    ;;
  *rtx3090*|*3090*|*a5000*|*a10*)
    GPU_LAYERS=47
    CTX_SIZE=16384
    ;;
  *a100*)
    GPU_LAYERS=49
    CTX_SIZE=32768
    ;;
  *t4*|*teslat4*)
    GPU_LAYERS=35
    CTX_SIZE=12288
    ;;
  *)
    # Автоматический расчёт по доступной памяти
    TOTAL_VRAM=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader -i 0 | awk '{print int($1/1024)}')
    echo "Неизвестный GPU. Обнаружено ${TOTAL_VRAM}ГБ VRAM"
    
    if [ $TOTAL_VRAM -ge 80 ]; then
      GPU_LAYERS=49
      CTX_SIZE=32768
    elif [ $TOTAL_VRAM -ge 32 ]; then
      GPU_LAYERS=47
      CTX_SIZE=32768
    elif [ $TOTAL_VRAM -ge 24 ]; then
      GPU_LAYERS=45
      CTX_SIZE=16384
    elif [ $TOTAL_VRAM -ge 16 ]; then
      GPU_LAYERS=35
      CTX_SIZE=8192
    else
      GPU_LAYERS=20
      CTX_SIZE=4096
    fi
    ;;
esac

echo "Параметры: --gpu-layers $GPU_LAYERS, --ctx-size $CTX_SIZE"

# Проверка существования модели
MODEL_PATH="/home/ubuntu/models/Qwen2.5-14B-Instruct-Q6_K.gguf"
if [ ! -f "$MODEL_PATH" ]; then
  echo "❌ Модель не найдена: $MODEL_PATH"
  echo "Совет: Скачайте модель и поместите в $MODEL_PATH"
  exit 1
fi

echo "Модель: $MODEL_PATH"

# Запуск llama-server
exec /home/ubuntu/llama.cpp/build/bin/llama-server \
  -m "$MODEL_PATH" \
  --gpu-layers $GPU_LAYERS \
  -c $CTX_SIZE \
  --temp 0.1 \
  --repeat-penalty 1.1 \
  -e \
  --host 127.0.0.1 \
  --port 8080 \
  "$@"
