#!/bin/bash

for year in $(seq 2010 2024); do
    echo -n "Processing year $year … "

    sed "s/{{YEAR}}/$year/g" q.sql | psql -d spatial > "smokes_over_lakes_united_state_and_canada${year}.csv"

    echo "done."
done

head -n 1 "smokes_over_lakes_united_state_and_canada2010.csv" > "smokes_over_lakes_united_state_and_canada.csv"

for year in $(seq 2010 2024); do
    tail -n +2 "smokes_over_lakes_united_state_and_canada${year}.csv" >> "smokes_over_lakes_united_state_and_canada.csv"
done