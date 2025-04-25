#!/bin/bash

# Настройки
BACKUP_DIR="/tmp/backup"
S3_BUCKET="s3://your-bucket-name"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="/var/log/backup_$DATE.log"
CRON_TAB="/var/spool/cron/crontabs/root"
ETC_DIR="/etc"
LOGS_DIR="/var/log"

# Функция для логирования
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Проверка, существует ли директория для бэкапов
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    log "Создана директория для бэкапов: $BACKUP_DIR"
fi

# Создание архива для /etc
log "Начало бэкапа директории /etc"
tar -czf "$BACKUP_DIR/etc_$DATE.tar.gz" -C "$ETC_DIR" . >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log "Бэкап /etc завершен успешно"
else
    log "Ошибка при бэкапе /etc"
    exit 1
fi

# Создание архива для логов
log "Начало бэкапа логов из $LOGS_DIR"
tar -czf "$BACKUP_DIR/logs_$DATE.tar.gz" -C "$LOGS_DIR" . >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log "Бэкап логов завершен успешно"
else
    log "Ошибка при бэкапе логов"
    exit 1
fi

# Создание архива для crontab
log "Начало бэкапа crontab"
cp "$CRON_TAB" "$BACKUP_DIR/crontab_$DATE" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log "Бэкап crontab завершен успешно"
else
    log "Ошибка при бэкапе crontab"
    exit 1
fi

# Загрузка файлов в S3-совместимое хранилище
log "Начало загрузки бэкапов в S3"
aws s3 cp "$BACKUP_DIR/etc_$DATE.tar.gz" "$S3_BUCKET/backup/etc_$DATE.tar.gz" >> "$LOG_FILE" 2>&1
aws s3 cp "$BACKUP_DIR/logs_$DATE.tar.gz" "$S3_BUCKET/backup/logs_$DATE.tar.gz" >> "$LOG_FILE" 2>&1
aws s3 cp "$BACKUP_DIR/crontab_$DATE" "$S3_BUCKET/backup/crontab_$DATE" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    log "Загрузка бэкапов завершена успешно"
else
    log "Ошибка при загрузке бэкапов в S3"
    exit 1
fi

# Очистка временных файлов
rm -rf "$BACKUP_DIR"
log "Временные файлы удалены"

# Завершение работы
log "Резервное копирование завершено успешно"
