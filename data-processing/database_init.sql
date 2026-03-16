-- setup result table
create table if not exists public.results
(
    event      varchar not null,
    name       varchar not null,
    rank       integer,
    points     integer,
    wins       integer,
    losses     integer,
    draws      integer,
    omw        numeric,
    gw         numeric,
    ogw        numeric,
    constraint results_pk
        primary key (event, name)
);

-- load data (columns as in results table)
COPY results FROM '/docker-entrypoint-initdb.d/all_events.csv' DELIMITER ',' CSV;


-- views

-- event winners with number of events won
-- all players with the highest amount of points are winners, other criteria are disregarded
create view public.event_wins_by_most_points(name, wins) as
WITH point_ranks AS (SELECT results.name,
                            rank() OVER (PARTITION BY results.event ORDER BY results.points DESC) AS rank
                     FROM results)
SELECT name,
       count(*) AS wins
FROM point_ranks
WHERE rank = 1
GROUP BY name;


-- this view calculates a ranking using total_points and average (omw, gw, ogw) only using the 6 best results
create view public.point_ranking(name, total_points, avg_omw, avg_gw, avg_ogw) as
WITH ranked_results AS (SELECT results.name,
                               results.points,
                               results.omw,
                               results.gw,
                               results.ogw,
                               row_number()
                               OVER (PARTITION BY results.name ORDER BY results.points DESC, results.omw DESC, results.gw DESC, results.ogw DESC) AS rank
                        FROM results)
SELECT name,
       sum(points)                 AS total_points,
       round(avg(omw), 2) AS avg_omw,
       round(avg(gw), 2)  AS avg_gw,
       round(avg(ogw), 2) AS avg_ogw
FROM ranked_results
WHERE rank <= 6
GROUP BY name
ORDER BY (sum(points)) DESC, (round(avg(omw)::numeric, 2)) DESC, (round(avg(gw)::numeric, 2)) DESC,
         (round(avg(ogw)::numeric, 2)) DESC;


-- effective ranking combining points, event wins and buchholz
create view public.ranking(rank, name, total_points, event_wins, avg_omw, avg_gw, avg_ogw) as
SELECT rank()
       OVER (ORDER BY pr.total_points DESC, ew.wins DESC, pr.avg_omw DESC, pr.avg_gw DESC, pr.avg_ogw DESC) AS rank,
       pr.name,
       pr.total_points,
       COALESCE(ew.wins, 0::bigint)                                                                         AS event_wins,
       pr.avg_omw,
       pr.avg_gw,
       pr.avg_ogw
FROM point_ranking pr
         LEFT JOIN event_wins_by_most_points ew ON pr.name::text = ew.name::text
ORDER BY (rank() OVER (ORDER BY pr.total_points DESC, ew.wins DESC, pr.avg_omw DESC, pr.avg_gw DESC, pr.avg_ogw DESC));


-- full ranking with all round results attached, to help create the table on the website
create view public.ranking_with_rounds
            (rank, name, total_points, event_wins, avg_omw, avg_gw, avg_ogw, d1, d2, d3, d4, d5, d6, d7, d8) as
SELECT r.rank,
       r.name,
       r.total_points,
       r.event_wins,
       r.avg_omw,
       r.avg_gw,
       r.avg_ogw,
       COALESCE(r1.points::character varying, '-'::character varying) AS d1,
       COALESCE(r2.points::character varying, '-'::character varying) AS d2,
       COALESCE(r3.points::character varying, '-'::character varying) AS d3,
       COALESCE(r4.points::character varying, '-'::character varying) AS d4,
       COALESCE(r5.points::character varying, '-'::character varying) AS d5,
       COALESCE(r6.points::character varying, '-'::character varying) AS d6,
       COALESCE(r7.points::character varying, '-'::character varying) AS d7,
       COALESCE(r8.points::character varying, '-'::character varying) AS d8
FROM ranking r
         LEFT JOIN results r1 ON r.name::text = r1.name::text AND r1.event::text = 'draft1'::text
         LEFT JOIN results r2 ON r.name::text = r2.name::text AND r2.event::text = 'draft2'::text
         LEFT JOIN results r3 ON r.name::text = r3.name::text AND r3.event::text = 'draft3'::text
         LEFT JOIN results r4 ON r.name::text = r4.name::text AND r4.event::text = 'draft4'::text
         LEFT JOIN results r5 ON r.name::text = r5.name::text AND r5.event::text = 'draft5'::text
         LEFT JOIN results r6 ON r.name::text = r6.name::text AND r6.event::text = 'draft6'::text
         LEFT JOIN results r7 ON r.name::text = r7.name::text AND r7.event::text = 'draft7'::text
         LEFT JOIN results r8 ON r.name::text = r8.name::text AND r8.event::text = 'draft8'::text
ORDER BY r.rank, r8.points DESC, r.name;


-- effective ranking formatted for markdown table
create view public.ranking_formatted(formatted) as
select
    '|' || lpad(rpad(rank::varchar, 3), 4) || '|'
        || lpad(rpad(name::varchar, 24), 25) || '|'
        || lpad(rpad(total_points::varchar, 4), 5) || '|'
        || lpad(rpad(event_wins::varchar, 2), 3)  || '|'
        || lpad(rpad(avg_omw::varchar, 5), 6) || '|'
        || lpad(rpad(avg_gw::varchar, 5), 6) || '|'
        || lpad(rpad(avg_ogw::varchar, 5), 6) || '|'
as formatted
from ranking;


-- full ranking formatted for markdown table
create view public.ranking_with_rounds_formatted(formatted) as
select
    '|' || lpad(rpad(rank::varchar, 3), 4) || '|'
        || lpad(rpad(name::varchar, 24), 25) || '|'
        || lpad(rpad(total_points::varchar, 4), 5) || '|'
        || lpad(rpad(event_wins::varchar, 2), 3)  || '|'
        || lpad(rpad(avg_omw::varchar, 5), 6) || '|'
        || lpad(rpad(avg_gw::varchar, 5), 6) || '|'
        || lpad(rpad(avg_ogw::varchar, 5), 6) || '|'
        || lpad(rpad(d1::varchar, 3), 4) || '|'
        || lpad(rpad(d2::varchar, 3), 4) || '|'
        || lpad(rpad(d3::varchar, 3), 4) || '|'
        || lpad(rpad(d4::varchar, 3), 4) || '|'
        || lpad(rpad(d5::varchar, 3), 4) || '|'
        || lpad(rpad(d6::varchar, 3), 4) || '|'
        || lpad(rpad(d7::varchar, 3), 4) || '|'
        || lpad(rpad(d8::varchar, 3), 4) || '|'
as formatted
from ranking_with_rounds;
