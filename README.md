# СТРУКТУРА РЕПОЗИТОРИЯ:

## Frontend

Пайплайн gitlab-ci включает в себя этапы:
  - проверка кода с помощью sonarqube
  - сборка фронтенда
  - загрузка собранного фронтенда в nexus
  - сборка образа из Dockerfile и загрузка в Gitlab registry
  - проверка собранного образа на уязвимости с помощью trivy, генерация отчёта

## Backend

Пайплайн gitlab-ci включает в себя этапы:
  - линт исходного кода
  - тестирование с помощью go test и sonarqube
  - сборка бекенда
  - загрузка собранного бекенда в nexus
  - сборка образа из Dockerfile и загрузка в Gitlab registry
  - проверка собранного образа на уязвимости с помощью trivy, генерация отчёта

## Packages

В пайплайне используется образ alpine:3.17.3
Для подготовки образа используется скрипт env.sh

Пайплайн gitlab-ci включает в себя этапы:
  - подготовку образа для запуска (передача переменных, запуска скрипта env.sh)
  - упаковка helm-чартов в архив и загрузка в nexus

helm-чарты:

- momo-store:
  - momo-store-backend
  - momo-store-frontend

- cert-manager

- ingress-nginx

- monitoring-tools:
  - alertmanager
  - grafana
  - prometheus

## Infrastructure

В пайплайне используется образ alpine:3.17.3
Для подготовки образа используется скрипт env.sh

Пайплайн gitlab-ci включает в себя этапы:
  - подготовку образа для запуска (передача переменных, запуска скрипта env.sh)
  - создание k8s-кластера и группы нод с помощью terraform
  - деплой вспомогательных сервисов с помощью helm-чартов
  - удалениее k8s-кластера и группы нод с помощью terraform

Скрипты:
  - scripts/deploy.sh - команды для запуска установки вспомогательных сервисов (ingress-nginx, cert-manager, cluster-issuer, prometheus, grafana, alertmanager)
  - scripts/prepare.sh - генерация конфигов terraform

## Application

В пайплайне используется образ alpine:3.17.3
Для подготовки образа используется скрипт env.sh

Пайплайн включает в себя этапы:
  - подготовку образа для запуска (передача переменных, запуска скрипта env.sh)
  - деплой приложений фронтенда и бекенда с помощью helm-чартов

Скрипты:
  - scripts/deploy.sh
    - настройка подключения к k8s-кластеру с помощью yc-cli
    - запуск установки приложений фронтенда и бекенда из helm-чарта
    - получение IP-адреса ингресс контроллера для А-записи DNS

---

**Адрес сайта:** momo.sirius.online

- prometheus-momo.sirius.online
- grafana-momo.sirius.online
- alertmanager-momo.sirius.online

---

## Momo Store aka Пельменная №2

<img width="400" alt="image" src="https://user-images.githubusercontent.com/9394918/167876466-2c530828-d658-4efe-9064-825626cc6db5.png">
