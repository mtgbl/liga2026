FROM node:20 AS build

WORKDIR /build

COPY data-processing/package.json .
COPY data-processing/package-lock.json .
RUN npm install

COPY data-processing/transform_eventlink.js .
COPY data-processing/transform.sh .
COPY data-processing/name_replacements.csv .
COPY event_data event_data
RUN bash transform.sh

FROM postgres:16

ENV POSTGRES_PASSWORD=test
ENV POSTGRES_DB=liga2026

COPY data-processing/database_init.sql /docker-entrypoint-initdb.d/
COPY --from=build /build/all_events.csv /docker-entrypoint-initdb.d/
