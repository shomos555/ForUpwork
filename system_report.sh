#!/bin/bash

# Путь к файлу для сохранения отчёта
LOG_FILE="/var/log/system_report_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Информация о дате и времени
echo "=== Отчёт системы на $(date) ===" > "$LOG_FILE"

# 1. Информация о загрузке процессора и памяти
echo -e "\n--- Загрузка процессора и памяти ---" >> "$LOG_FILE"
top -b -n 1 | head -n 20 >> "$LOG_FILE"

# 2. Информация о дисковом пространстве
echo -e "\n--- Использование дисков ---" >> "$LOG_FILE"
df -h >> "$LOG_FILE"

# 3. Информация о дисковой активности
echo -e "\n--- Загрузка диска (I/O) ---" >> "$LOG_FILE"
iostat -xz 1 1 >> "$LOG_FILE"

# 4. Информация о сетевой активности
echo -e "\n--- Сетевая активность (RX/TX) ---" >> "$LOG_FILE"
if command -v iftop >/dev/null 2>&1; then
    iftop -t -s 5 >> "$LOG_FILE"
else
    echo "iftop не установлен, пропускаем сбор сетевой информации" >> "$LOG_FILE"
fi

# 5. Использование swap
echo -e "\n--- Использование swap ---" >> "$LOG_FILE"
free -h >> "$LOG_FILE"

# 6. Топ процессов по потреблению памяти и CPU
echo -e "\n--- Топ процессов по памяти ---" >> "$LOG_FILE"
ps aux --sort=-%mem | head -n 10 >> "$LOG_FILE"

echo -e "\n--- Топ процессов по CPU ---" >> "$LOG_FILE"
ps aux --sort=-%cpu | head -n 10 >> "$LOG_FILE"

# 7. Последние логи системных сообщений
echo -e "\n--- Последние системные логи ---" >> "$LOG_FILE"
journalctl -xe --no-pager | tail -n 50 >> "$LOG_FILE"

# 8. Информация об uptime
echo -e "\n--- Время работы системы ---" >> "$LOG_FILE"
uptime >> "$LOG_FILE"

# 9. Список работающих сервисов
echo -e "\n--- Активные сервисы ---" >> "$LOG_FILE"
systemctl list-units --type=service --state=running >> "$LOG_FILE"

# Сообщение о завершении
echo -e "\nОтчёт сохранён в $LOG_FILE"

