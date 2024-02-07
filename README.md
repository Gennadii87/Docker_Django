**Для сборки образа  Django (Linux, nginx, Django, Postgres, Gunicorn)**

Скопируйте все файлы в одну директорию и запустите сборку образа : `docker build -t django_docker .`

Запустите контейнер и пробросте порты: `docker run -d -p 8888:80 -p8889:8000 django_docker`

 в Docker файле оставлены коментарии для понимания что делают команды 