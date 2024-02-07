FROM ubuntu

# Устанавливаем переменные среды для Django
ENV DJANGO_SUPERUSER_PASSWORD=admin
ENV PGDATA /var/lib/postgresql/data
# Устанавливаем переменную среды для обхода интерактивных запросов
ARG DEBIAN_FRONTEND=noninteractive

# Обновляем пакеты и устанавливаем необходимые зависимости
RUN apt-get update && \
    apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    postgresql-client \
    postgresql \
    sudo \
    tzdata \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Создаем виртуальное окружение для Python
RUN python3 -m venv /venv
ENV PATH="/venv/bin:$PATH"

# Копируем конфигурацию Nginx
COPY ./siteconfig.conf /etc/nginx/sites-enabled/default

# Устанавливаем Python зависимости
RUN pip install "django>=4.0,<5.0" psycopg2-binary gunicorn

# Устанавливаем рабочую директорию
WORKDIR /projectdjango

# Определяем тома
VOLUME /projectdjango /var/lib/postgresql/data

COPY ./run.sh /tmp/run.sh

# Экспонируем порты
EXPOSE 80 8000 5432

# Создаем каталог для PostgreSQL и устанавливаем права
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 700 "$PGDATA"

# Переключаемся на пользователя postgres, запускаем PostgreSQL и меняем пароль
USER postgres
RUN /etc/init.d/postgresql start && psql --command "ALTER USER postgres PASSWORD 'postgres';"

# Возвращаемся к пользователю root, обновляем конфигурацию PostgreSQL
USER root
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/14/main/postgresql.conf

# Создаем Django проект и применяем миграции
RUN django-admin startproject django_project .
RUN python3 manage.py migrate
# Изменяем ALLOWED_HOSTS в settings.py
RUN sed -i "s/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = ['*']/" /projectdjango/django_project/settings.py
# Создаем суперпользователя Django
RUN python3 manage.py createsuperuser --noinput --username admin --email test@test.com

# Указываем точку входа для контейнера
ENTRYPOINT ["sh", "/tmp/run.sh"]
