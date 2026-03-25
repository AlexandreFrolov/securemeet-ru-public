#!/bin/bash
echo "=== Проверка поддержки GPU ==="

# Информация о системе
echo "GPU в системе:"
nvidia-smi --query-gpu=index,name,compute_cap,memory.total --format=csv

echo -e "\nПоддерживаемые архитектуры в libggml-cuda.so:"
if [ -f /home/ubuntu/llama.cpp/build/bin/libggml-cuda.so ]; then
  strings /home/ubuntu/llama.cpp/build/bin/libggml-cuda.so | grep -o "sm_[0-9]*" | sort -u
else
  echo "⚠️  Библиотека не найдена. Выполните сначала ./build-llama.sh"
fi

echo -e "\nСвободная память:"
free -h | grep -A1 Mem
df -h /home/ubuntu/models 2>/dev/null || echo "Директория /home/ubuntu/models не существует"

echo -e "\nВерсии:"
nvcc --version | grep "release"
nvidia-smi | grep "Driver Version"
