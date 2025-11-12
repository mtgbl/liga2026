# Liga 2026 results

## Add event results
Add the standings table from the event in eventlink as csv in `/event_data `.
The file name will be used as event name. For league purposes, name the event csv files `draft1.csv`, `draft2.csv` and so on.

## (Re-)Build database
_Requires: Docker_

```sh
docker build -t liga2026 . && docker run -it --rm -p 5432:5432 liga2026
```

## Show ranking
_Requires: psql_
```sh
PGPASSWORD=test psql -U postgres -d liga2026 -h localhost -c "select * from ranking"
```
