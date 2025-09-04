#!/bin/bash
if [ -f ./all_events.csv ]; then
    rm ./all_events.csv
fi

for f in example_data/*.csv; do
    node transform_eventlink.js "$f" >> ./all_events.csv
done
