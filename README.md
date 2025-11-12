# Liga 2026 results

## Add event results
Add the standings table from the event in eventlink as csv in `/event_data `.
The file name will be used as event name. For league purposes, name the event csv files `draft1.csv`, `draft2.csv` and so on.

## How the ranking works
The calculation all happens in the database. All relevant code is in `database_init.sql`, mostly as views.

`event_wins_by_most_points` determines the winners of the individual events, which are all players that have the most points in that events.

`point_ranking` takes the top 6 drafts of each player and creates the sum of points of those and averages of the buchholz values (omw, gw, ogw).

`ranking` combines the event wins and top6 results and orders according to the liga rules.

## (Re-)Build database
_Requires: Docker_

```sh
docker build -t liga2026 . && docker run -it --rm -p 5432:5432 liga2026
```

## Show ranking
_Requires: psql + the database above running_
```sh
PGPASSWORD=test psql -U postgres -d liga2026 -h localhost -c "select * from ranking"
```
