#!/bin/bash
set -e

echo "=== Установка зависимостей ==="

# Обновление системы
sudo apt update && sudo apt upgrade -y

# Основные зависимости
sudo apt install -y \
  build-essential \
  cmake \
  git \
  python3-pip \
  wget \
  curl \
  libssl-dev \
  pkg-config

# CUDA Toolkit (если не установлен)
if [ ! -f "/usr/local/cuda/bin/nvcc" ]; then
  echo "CUDA Toolkit не найден. Установка..."

  wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  rm cuda-keyring_1.1-1_all.deb

  sudo apt update
  sudo apt install -y cuda-toolkit-12-3

  # Прописать PATH постоянно
  if ! grep -q 'cuda/bin' ~/.bashrc; then
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}' >> ~/.bashrc
  fi
else
  echo "CUDA Toolkit уже установлен: $(ls /usr/local/cuda/bin/nvcc)"
fi

# Добавить в PATH для текущего сеанса (критично для дочерних скриптов)
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

# Проверка
echo "=== Проверка версий ==="
nvcc --version | grep "release"
nvidia-smi | grep "Driver Version"
nvidia-smi --query-gpu=name,compute_cap --format=csv

echo "✅ Зависимости установлены!"
