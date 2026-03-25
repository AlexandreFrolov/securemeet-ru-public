#!/bin/bash
set -e

echo "=== Сборка LLAMA.cpp ==="

# Параметры
LLAMA_DIR="/home/ubuntu/llama.cpp"
BUILD_DIR="${LLAMA_DIR}/build"
ARCHS="75;80;86;89;90"  # Поддержка: T4, A100, 3090/4090/A5000/A10, H100/H200

# Клонирование (если не существует)
if [ ! -d "$LLAMA_DIR" ]; then
  git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
fi

cd "$LLAMA_DIR"

# Очистка предыдущей сборки
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Конфигурация CMake
echo "Конфигурация с архитектурами: $ARCHS"
cmake .. \
  -DGGML_CUDA=ON \
  -DCMAKE_CUDA_ARCHITECTURES="$ARCHS" \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_SERVER=ON

# Сборка
make -j$(nproc) llama-server

# Проверка
echo "=== Проверка библиотеки ==="
strings ./bin/libggml-cuda.so | grep -o "sm_[0-9]*" | sort -u

echo "✅ Сборка завершена!"
echo "Бинарник: $BUILD_DIR/bin/llama-server"
