FROM node:20 AS build

WORKDIR /build

COPY package.json .
COPY package-lock.json .
COPY transform_eventlink.js .
COPY transform.sh .
copy name_replacements.csv .
COPY example_data example_data

RUN npm install && \
    bash transform.sh

FROM postgres:16

ENV POSTGRES_PASSWORD=test
ENV POSTGRES_DB=liga2026

COPY database_init.sql /docker-entrypoint-initdb.d/
COPY --from=build /build/all_events.csv /docker-entrypoint-initdb.d/
