#!/bin/bash
set -e

echo "======================================"
echo "  Установка LLAMA.cpp для всех GPU"
echo "======================================"

# Шаг 1: Зависимости
echo -e "\n[1/6] Установка зависимостей..."
chmod +x install-prerequisites-debian.sh
./install-prerequisites-debian.sh

# Шаг 2: Сборка
echo -e "\n[2/6] Сборка LLAMA.cpp..."
chmod +x build-llama-debian.sh
./build-llama-debian.sh

# Шаг 3: Скрипт-обёртка
echo -e "\n[3/6] Установка скрипта-обёртки..."
sudo install -m 755 llama-server-wrapper.sh /usr/local/bin/llama-server-wrapper.sh
sudo chown root:root /usr/local/bin/llama-server-wrapper.sh

# Шаг 4: Сервис
echo -e "\n[4/6] Настройка systemd сервиса..."
sudo cp llama-server.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable llama-server.service

# Шаг 5: Проверка
echo -e "\n[5/6] Проверка поддержки GPU..."
chmod +x check-gpu-support.sh
./check-gpu-support.sh

# Шаг 6: Тест (опционально)
echo -e "\n[6/6] Тестовый запуск (опционально)..."
read -p "Запустить тестовый запуск? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  chmod +x test-llama.sh
  if ./test-llama.sh; then
    echo -e "\n✅ Установка успешно завершена!"
    echo "Запустите сервис: sudo systemctl start llama-server.service"
    echo "Мониторинг: ./monitor-llama.sh"
  else
    echo -e "\n⚠️  Тест не пройден, но установка завершена."
    echo "Проверьте логи и попробуйте запустить сервис вручную."
  fi
else
  echo -e "\n✅ Установка завершена! Тест пропущен."
  echo "Запустите сервис: sudo systemctl start llama-server.service"
  echo "Мониторинг: ./monitor-llama.sh"
fi

