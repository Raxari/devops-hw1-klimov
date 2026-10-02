# ДЗ 1 — заметки в PostgreSQL

Климов И. А., БИСТ-23-ПО-2. Дисциплина «Инструменты DevOps», вариант 01.

| Параметр | Значение |
|---|---|
| Префикс | `klimov-01` |
| Базовый образ приложения | `python:3.12-alpine` |
| Образ базы | `postgres:16-alpine` |
| Порт приложения | `8003:5001` |
| Порт базы на хосте | `8005:5432` |
| Именованный том | `klimov-01-data` |
| Маркер | `sitelab` |

## Запуск

Нужны Linux или WSL2, работающий Docker Engine, Bash и curl.
Из каталога проекта выполните одну команду:

```bash
bash run.sh
```

Сценарий собирает `klimov-01/probe:2.0`, создаёт именованный том и запускает
контейнеры базы и приложения. При повторном запуске оба контейнера
пересоздаются, а том с заметками сохраняется. Сценарий ждёт готовности базы
через запрос `/notes` и завершается ошибкой, если сервис не готов за отведённое время.

Приложение подключается к опубликованному порту базы через
`host.docker.internal:8005`. Имя добавляется параметром
`--add-host host.docker.internal:host-gateway`; используется стандартная сеть bridge.

## Проверка

```bash
curl -sS http://localhost:8003/me
curl -sS -X POST http://localhost:8003/notes -d 'text=klimov-01-sitelab'
curl -sS http://localhost:8003/notes
```

Каждая заметка хранит текст, имя контейнера, версию приложения и время создания.

## Обновление приложения до 2.1

База и её том продолжают работать. Выполните:

```bash
docker build --progress=plain --build-arg VERSION=2.1 -t klimov-01/probe:2.1 .
docker rm -f klimov-01-web
docker run -d --name klimov-01-web \
  -p 8003:5001 \
  --add-host host.docker.internal:host-gateway \
  -e APP_PORT=5001 -e MARKER=sitelab \
  -e DATABASE_URL=postgresql://postgres:lab@host.docker.internal:8005/lab \
  klimov-01/probe:2.1
```

После запуска новой версии прежние заметки доступны через `/notes`.
Повторный запуск `run.sh` запускает версию 2.0, сохраняя тот же том.
Учётные данные `postgres:lab` предназначены для учебного стенда.
