#!/bin/bash

echo "=== Статус сервиса ==="
if systemctl is-active --quiet llama-server.service; then
  echo "✅ Сервис запущен"
  sudo systemctl status llama-server.service --no-pager | head -20
else
  echo "❌ Сервис не запущен"
  sudo systemctl status llama-server.service --no-pager
fi

echo -e "\n=== Последние 100 строк логов ==="
sudo journalctl -u llama-server.service -n 100 --no-pager

echo -e "\n=== Использование ресурсов ==="
if ps aux | grep -q "[l]lama-server"; then
  ps aux | grep "[l]lama-server" | awk '{print "CPU: "$3"% MEM: "$4"% PID: "$2}'
  nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv 2>/dev/null || echo "GPU информация недоступна"
else
  echo "Процесс llama-server не найден"
fi

echo -e "\n=== Проверка API ==="
if curl -sf http://localhost:8080/health > /dev/null 2>&1; then
  echo "✅ API доступен"
  curl -s http://localhost:8080/health | python3 -m json.tool 2>/dev/null || cat
else
  echo "❌ API недоступен"
  echo "Проверьте: sudo systemctl status llama-server.service"
fi
