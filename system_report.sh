#!/bin/bash

# Получаем имя хоста
HOSTNAME=$(hostname)

# Путь к файлу для сохранения отчёта с добавлением имени хоста
LOG_FILE="/var/log/${HOSTNAME}_system_report_$(date '+%Y-%m-%d_%H-%M-%S').log"

# 1. Информация о загрузке процессора и памяти
echo "=== Отчёт системы на $(date) от $HOSTNAME ===" > "$LOG_FILE"
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
    echo "iftop не установлен, используем netstat" >> "$LOG_FILE"
    netstat -tunlp >> "$LOG_FILE"
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

# 9. Информация об архитектуре системы
echo -e "\n--- Архитектура системы ---" >> "$LOG_FILE"
arch >> "$LOG_FILE"

# 10. Информация о дистрибутиве
echo -e "\n--- Информация о дистрибутиве ---" >> "$LOG_FILE"
cat /etc/os-release >> "$LOG_FILE"

# 11. Средняя загрузка системы
echo -e "\n--- Средняя загрузка системы ---" >> "$LOG_FILE"
cat /proc/loadavg >> "$LOG_FILE"

# 12. Температура процессора (если доступно)
echo -e "\n--- Температура системы ---" >> "$LOG_FILE"
if command -v sensors >/dev/null 2>&1; then
    sensors >> "$LOG_FILE"
else
    echo "Датчики температуры недоступны" >> "$LOG_FILE"
fi

# 13. Активные сервисы
echo -e "\n--- Активные сервисы ---" >> "$LOG_FILE"
systemctl list-units --type=service --state=running >> "$LOG_FILE"

# 14. Ограничения по использованию ресурсов
echo -e "\n--- Ограничения по использованию ресурсов ---" >> "$LOG_FILE"
ulimit -a >> "$LOG_FILE"

# 15. Использование дискового пространства в /var/log
echo -e "\n--- Использование дискового пространства в /var/log ---" >> "$LOG_FILE"
du -h --max-depth=1 /var/log >> "$LOG_FILE"

# 16. Состояние RAID (если используется)
echo -e "\n--- Состояние RAID ---" >> "$LOG_FILE"
if [ -f /proc/mdstat ]; then
    cat /proc/mdstat >> "$LOG_FILE"
else
    echo "RAID не используется" >> "$LOG_FILE"
fi

# 17. Информация о сетевых соединениях через netstat
echo -e "\n--- Сетевые соединения (netstat) ---" >> "$LOG_FILE"
netstat -tunlp >> "$LOG_FILE"

# Автоматическая загрузка отчёта на сервер через curl или wget
UPLOAD_URL="http://<server_ip>:5454/upload.php"
USERNAME="your_username"
PASSWORD="your_password"

# Проверяем, установлен ли curl, если нет, используем wget
if command -v curl >/dev/null 2>&1; then
    echo "Используем curl для загрузки файла"
    curl -u "$USERNAME:$PASSWORD" -X POST -F "file=@$LOG_FILE" $UPLOAD_URL
elif command -v wget >/dev/null 2>&1; then
    echo "curl не найден, используем wget для загрузки файла"
    wget --user="$USERNAME" --password="$PASSWORD" --post-file="$LOG_FILE" "$UPLOAD_URL"
else
    echo "Ошибка: ни curl, ни wget не установлены. Не могу загрузить отчёт."
fi

# Сообщение о завершении
echo -e "\nОтчёт сохранён в $LOG_FILE и загружен на сервер."
