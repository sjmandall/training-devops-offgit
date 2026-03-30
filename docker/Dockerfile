FROM alpine:3.20 AS prepare
WORKDIR /src
COPY app/site/ /src/site/
COPY app/config/app.env.example /src/config/app.env.example

FROM php:8.2-apache

ENV APP_HOME=/var/www/website \
    DB_HOST=localhost \
    DB_PORT=3306 \
    DB_NAME=trainingdb \
    DB_USER=trainingapp \
    DB_PASSWORD=StrongPassword!

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && a2enmod rewrite

RUN mkdir -p ${APP_HOME} /var/www/config

COPY docker/apache/website.conf /etc/apache2/sites-available/website.conf

RUN a2dissite 000-default.conf \
    && a2ensite website.conf

COPY --from=prepare /src/site/ ${APP_HOME}/
COPY --from=prepare /src/config/app.env.example /var/www/config/app.env.example

RUN chown -R www-data:www-data ${APP_HOME} /var/www/config

WORKDIR ${APP_HOME}

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -fsS http://127.0.0.1/info.php || curl -fsS http://127.0.0.1/index.php || exit 1

USER www-data

EXPOSE 80
