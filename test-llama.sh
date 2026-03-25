#!/bin/bash
set -e

echo "=== Тестовый запуск LLAMA ==="

# Проверка существования бинарника
if [ ! -f /home/ubuntu/llama.cpp/build/bin/llama-server ]; then
  echo "❌ Бинарник не найден. Выполните сначала ./build-llama.sh"
  exit 1
fi

# Проверка существования модели
MODEL_PATH="/home/ubuntu/models/Qwen2.5-14B-Instruct-Q6_K.gguf"
if [ ! -f "$MODEL_PATH" ]; then
  echo "❌ Модель не найдена: $MODEL_PATH"
  echo "Совет: Скачайте модель и поместите в $MODEL_PATH"
  exit 1
fi

# Проверка свободной памяти
FREE_VRAM=$(nvidia-smi --query-gpu=memory.free --format=csv,noheader -i 0 | awk '{print $1}')
if [ "$FREE_VRAM" -lt 10000 ]; then
  echo "⚠️  Мало свободной VRAM: ${FREE_VRAM} MiB"
  nvidia-smi
  read -p "Продолжить? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

echo "Свободно VRAM: ${FREE_VRAM} MiB"

# Запуск с таймаутом
cd /home/ubuntu/llama.cpp/build/bin

timeout 300s ./llama-server \
  -m "$MODEL_PATH" \
  --gpu-layers 10 \
  --port 8081 \
  --verbose 2>&1 | tee /tmp/llama-test.log &

LLAMA_PID=$!
echo "Запущен процесс: $LLAMA_PID"

# Ждём инициализации
sleep 15

# Проверка запуска
if ps -p $LLAMA_PID > /dev/null; then
  echo "✅ Сервер запущен (PID: $LLAMA_PID)"
  
  # Проверка готовности API
  echo "Проверка готовности API..."
  for i in {1..30}; do
    if curl -sf http://localhost:8081/health > /dev/null 2>&1; then
      echo "✅ API готов!"
      kill $LLAMA_PID 2>/dev/null
      wait $LLAMA_PID 2>/dev/null || true
      echo "Тестовый запуск успешен!"
      exit 0
    fi
    echo "Ожидание... ($i/30)"
    sleep 2
  done
  
  echo "❌ API не ответил за 60 секунд"
  echo "Последние строки лога:"
  tail -50 /tmp/llama-test.log
  kill $LLAMA_PID 2>/dev/null
  wait $LLAMA_PID 2>/dev/null || true
  exit 1
else
  echo "❌ Сервер не запустился"
  cat /tmp/llama-test.log | tail -50
  exit 1
fi
