#!/bin/bash
set -e

echo "=== Сборка LLAMA.cpp ==="

# Убедиться что nvcc в PATH
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}
export CUDACXX=/usr/local/cuda/bin/nvcc

# Проверка nvcc
if ! command -v nvcc &> /dev/null; then
  echo "❌ nvcc не найден даже после экспорта PATH!"
  echo "Проверьте: ls /usr/local/cuda/bin/nvcc"
  exit 1
fi
echo "nvcc: $(nvcc --version | grep release)"

# Параметры
LLAMA_DIR="/home/ubuntu/llama.cpp"
BUILD_DIR="${LLAMA_DIR}/build"
ARCHS="75;80;86;89;90"  # T4, A100, 3090/4090/A5000/A10, H100/H200

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
  -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLAMA_BUILD_SERVER=ON

# Сборка
make -j$(nproc) llama-server

# Проверка
echo "=== Проверка библиотеки ==="
strings ./bin/libggml-cuda.so | grep -o "sm_[0-9]*" | sort -u

echo "✅ Сборка завершена!"
echo "Бинарник: $BUILD_DIR/bin/llama-server"
