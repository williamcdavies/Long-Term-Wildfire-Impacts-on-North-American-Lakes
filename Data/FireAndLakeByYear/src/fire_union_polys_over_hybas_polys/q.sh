#!/bin/bash

for year in $(seq 2024 -1 1984); do
    echo "Processing year $year …"

    # Script 1: compute watersheds with overlap
    sed "s/{{YEAR}}/$year/g" q.true.sql | psql -d spatial -o "fire_polys_over_hybas${year}_overlap_true.csv"

    # Script 2: compute watersheds without overlap
    sed "s/{{YEAR}}/$year/g" q.false.sql | psql -d spatial -o "fire_polys_over_hybas${year}_overlap_false.csv"

    # Concatenate with TRUE rows first
    cat "fire_polys_over_hybas${year}_overlap_true.csv" \
        <(tail -n +2 "fire_polys_over_hybas${year}_overlap_false.csv") \
        > "fire_polys_over_hybas${year}.csv"

    echo "Completed year $year."
done