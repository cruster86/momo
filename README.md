# Настройка инфраструктуры:

1. Для создания k8s-кластера запустить пайплайн: `infrastructure >> create cluster`
2. Для установки инфраструктурных сервисов запустить пайплайн: `infrastructure >> deploy soft`
3. Для удаления k8s-кластера запустить пайплайн: `infrastructure >> destory cluster`

# Утановка фронтенда и бекенда пельменной:

1. Создать релизный тэг
2. Подождать завершения выполенения пайплайнов по сборке образов и их загрузке в Gitlab-репозиторий
3. Подождать завершения выполенения пайплайна загруки helm-чартов в nexus-репозиторий
4. Запустить пайплайн установки фронтенда и бекенда: `application >> deploy momo`

# СТРУКТУРА РЕПОЗИТОРИЯ:

## Директория Frontend

Пайплайн frontend включает в себя этапы:
  - проверка кода с помощью sonarqube
  - сборка фронтенда
  - загрузка собранного фронтенда в nexus
  - сборка образа из Dockerfile и загрузка в Gitlab registry
  - проверка собранного образа на уязвимости с помощью trivy, генерация отчёта

## Директория Backend

Пайплайн backend включает в себя этапы:
  - линт исходного кода
  - тестирование с помощью go test и sonarqube
  - сборка бекенда
  - загрузка собранного бекенда в nexus
  - сборка образа из Dockerfile и загрузка в Gitlab registry
  - проверка собранного образа на уязвимости с помощью trivy, генерация отчёта

## Директория Packages

В пайплайне используется образ alpine:3.17.3

Для подготовки образа используется скрипт `env.sh`

Repository url: https://nexus.k8s.praktikum-services.tech/repository/momo-store-vladislav-lesnik-helm/

Пайплайн packages включает в себя этапы:
  - упаковка helm-чартов в архив и загрузка в nexus

helm-чарты:

- momo-store:
  - momo-store-backend
  - momo-store-frontend

- ingress-nginx

- monitoring-tools:
  - alertmanager
  - grafana
  - prometheus

## Директория Infrastructure

В пайплайне используется образ alpine:3.17.3

Для подготовки образа используется скрипт `env.sh`

Пайплайн infrastructure включает в себя этапы:
  - создание k8s-кластера и группы нод с помощью terraform
  - деплой инфраструктурных сервисов с помощью helm-чартов
  - удалениее k8s-кластера и группы нод с помощью terraform

Скрипты:
  - `deploy.sh` - команды для запуска установки инфраструктурных сервисов:
    - ingress-nginx
    - cert-manager
    - cluster-issuer
    - prometheus
    - grafana
    - alertmanager
    - loki
    - kube-state-metrics
  - `prepare.sh` - генерация конфигов terraform

## Директория Application

В пайплайне используется образ alpine:3.17.3

Для подготовки образа используется скрипт `env.sh`

Пайплайн application включает в себя этапы:
  - деплой приложений фронтенда и бекенда с помощью helm-чартов

Скрипты:
  - `deploy.sh`
    - настройка подключения к k8s-кластеру с помощью yc-cli
    - запуск установки приложений фронтенда и бекенда из helm-чарта
    - получение IP-адреса ингресс контроллера для А-записи DNS

## Директория Scripts

`env.sh` - скрипт для подготовки окружения в образе alpine:3.17.3

---

**Адрес сайта пельменной:** momo.sirius.online

- prometheus-momo.sirius.online
- grafana-momo.sirius.online
- alertmanager-momo.sirius.online

---

## Momo Store aka Пельменная №2

<img width="600" alt="image" src="https://user-images.githubusercontent.com/9394918/167876466-2c530828-d658-4efe-9064-825626cc6db5.png">
