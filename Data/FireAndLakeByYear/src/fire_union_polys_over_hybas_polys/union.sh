#!/bin/bash

# Usage: `sh union.sh`

for year in $(seq 2024 -1 1984); do
    echo "Computing and inserting union for year $year …"
    
    sed -e "s/{{YEAR}}/$year/g" \
        union.sql | psql -d spatial

    echo "Done."
done