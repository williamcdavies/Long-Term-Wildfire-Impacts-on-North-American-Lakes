#!/bin/bash

for year in $(seq 2025 -1 2005); do
    echo -n "Processing year $year … "

    sed "s/{{YEAR}}/$year/g" q.alt.sql | psql -d spatial -o "wfrtl_composite${year}.csv"

    echo "done."
done