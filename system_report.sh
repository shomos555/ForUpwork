#!/bin/bash

# Проверяем, переданы ли IP сервера, имя пользователя и пароль
if [ "$#" -ne 3 ]; then
  echo "Использование: $0 <IP сервера> <имя пользователя> <пароль>"
  exit 1
fi

# Получаем аргументы
SERVER_IP=$1
USERNAME=$2
PASSWORD=$3

# Жестко заданный URL с использованием переданного IP
UPLOAD_URL="http://$SERVER_IP:5454/upload.php"

# Получаем директорию, где находится скрипт
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Получаем имя хоста
HOSTNAME=$(hostname)

# Путь к файлу для сохранения отчёта с добавлением имени хоста
LOG_FILE="$SCRIPT_DIR/${HOSTNAME}_system_report_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Функция для проверки доступности команды
check_command() {
  command -v "$1" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Ошибка: команда $1 не найдена!" >> "$LOG_FILE"
    echo "Ошибка: команда $1 не найдена!" >&2
  fi
}

# 1. Информация о загрузке процессора и памяти
echo "=== Отчёт системы на $(date) от $HOSTNAME ===" > "$LOG_FILE"
check_command "top" && top -b -n 1 | head -n 20 >> "$LOG_FILE"

# 2. Информация о дисковом пространстве
echo -e "\n--- Использование дисков ---" >> "$LOG_FILE"
check_command "df" && df -h >> "$LOG_FILE"

# 3. Информация о дисковой активности
echo -e "\n--- Загрузка диска (I/O) ---" >> "$LOG_FILE"
check_command "iostat" && iostat -xz 1 1 >> "$LOG_FILE"

# 4. Информация о сетевой активности
echo -e "\n--- Сетевая активность (RX/TX) ---" >> "$LOG_FILE"
if check_command "iftop"; then
    iftop -t -s 5 >> "$LOG_FILE"
elif check_command "netstat"; then
    netstat -tunlp >> "$LOG_FILE"
else
    echo "Команды iftop и netstat не найдены" >> "$LOG_FILE"
fi

# 5. Использование swap
echo -e "\n--- Использование swap ---" >> "$LOG_FILE"
check_command "free" && free -h >> "$LOG_FILE"

# 6. Топ процессов по потреблению памяти и CPU
echo -e "\n--- Топ процессов по памяти ---" >> "$LOG_FILE"
check_command "ps" && ps aux --sort=-%mem | head -n 10 >> "$LOG_FILE"

echo -e "\n--- Топ процессов по CPU ---" >> "$LOG_FILE"
check_command "ps" && ps aux --sort=-%cpu | head -n 10 >> "$LOG_FILE"

# 7. Последние логи системных сообщений
echo -e "\n--- Последние системные логи ---" >> "$LOG_FILE"
check_command "journalctl" && journalctl -xe --no-pager | tail -n 50 >> "$LOG_FILE"

# 8. Информация об uptime
echo -e "\n--- Время работы системы ---" >> "$LOG_FILE"
check_command "uptime" && uptime >> "$LOG_FILE"

# 9. Информация об архитектуре системы
echo -e "\n--- Архитектура системы ---" >> "$LOG_FILE"
check_command "arch" && arch >> "$LOG_FILE"

# 10. Информация о дистрибутиве
echo -e "\n--- Информация о дистрибутиве ---" >> "$LOG_FILE"
check_command "cat" && cat /etc/os-release >> "$LOG_FILE"

# 11. Средняя загрузка системы
echo -e "\n--- Средняя загрузка системы ---" >> "$LOG_FILE"
check_command "cat" && cat /proc/loadavg >> "$LOG_FILE"

# 12. Температура процессора (если доступно)
echo -e "\n--- Температура системы ---" >> "$LOG_FILE"
if check_command "sensors"; then
    sensors >> "$LOG_FILE"
else
    echo "Датчики температуры недоступны" >> "$LOG_FILE"
fi

# 13. Активные сервисы
echo -e "\n--- Активные сервисы ---" >> "$LOG_FILE"
check_command "systemctl" && systemctl list-units --type=service --state=running >> "$LOG_FILE"

# 14. Ограничения по использованию ресурсов
echo -e "\n--- Ограничения по использованию ресурсов ---" >> "$LOG_FILE"
check_command "ulimit" && ulimit -a >> "$LOG_FILE"

# 15. Использование дискового пространства в /var/log
echo -e "\n--- Использование дискового пространства в /var/log ---" >> "$LOG_FILE"
check_command "du" && du -h --max-depth=1 /var/log >> "$LOG_FILE"

# 16. Состояние RAID (если используется)
echo -e "\n--- Состояние RAID ---" >> "$LOG_FILE"
if [ -f /proc/mdstat ]; then
    cat /proc/mdstat >> "$LOG_FILE"
else
    echo "RAID не используется" >> "$LOG_FILE"
fi

# 17. Информация о сетевых соединениях через netstat
echo -e "\n--- Сетевые соединения (netstat) ---" >> "$LOG_FILE"
check_command "netstat" && netstat -tunlp >> "$LOG_FILE"

# Автоматическая загрузка отчёта на сервер через curl или wget
if check_command "curl"; then
    echo "Используем curl для загрузки файла"
    curl -u "$USERNAME:$PASSWORD" -X POST -F "file=@$LOG_FILE" $UPLOAD_URL
elif check_command "wget"; then
    echo "curl не найден, используем wget для загрузки файла"
    wget --user="$USERNAME" --password="$PASSWORD" --post-file="$LOG_FILE" "$UPLOAD_URL"
else
    echo "Ошибка: ни curl, ни wget не установлены. Не могу загрузить отчёт." >> "$LOG_FILE"
    echo "Ошибка: ни curl, ни wget не установлены. Не могу загрузить отчёт." >&2
fi

# Сообщение о завершении
echo -e "\nОтчёт сохранён в $LOG_FILE и загружен на сервер."
