#!/bin/bash

# Output file for DOIs
doi_output_file="zenodo_dois.txt"

# Clear output file
> "$doi_output_file"

# Current date
date=$(date --iso-8601)


# Find all README.yml files and extract the zenodo DOI key
find NMRLipidsDB -name "README.yaml" | while read -r file; do
    echo "Processing $file"

    doi=$(grep -o 'DOI: .*10.5281/zenodo.*' "$file" | awk '{print $2}')
    if [ -n "$doi" ]; then
        echo "DOI found: $doi"
        echo "$doi" >> "$doi_output_file" 
    else
        echo "No DOI found in $file"
    fi
done

mkdir -p traffic
stats_output_file="traffic/zenodo_stats.csv"

if [ ! -f "$stats_output_file" ]; then
    echo "doi,date,downloads,unique_downloads,views,unique_views,version_downloads,version_unique_downloads,version_views,version_unique_views" > "$stats_output_file"
fi

mapfile -t dois_array < zenodo_dois.txt

for doi in "${dois_array[@]}"; do
    # remove the base DOI part
    identifier=$(echo "$doi" | sed 's/10\.5281\/zenodo\.//')
    #echo "DOI $doi"
    #echo "ID $identifier"

    # Fetch JSON data
    response=$(curl -s "https://zenodo.org/api/records/$identifier")

    # Check if successful
    if [[ $? -eq 0 ]]; then
        #echo "URL https://zenodo.org/api/records/$identifier"
	#echo "RESPONSE: $response" 

        downloads=$(echo "$response" | jq '.stats.downloads')
        unique_downloads=$(echo "$response" | jq '.stats.unique_downloads')
        views=$(echo "$response" | jq '.stats.views')
        unique_views=$(echo "$response" | jq '.stats.unique_views')
        version_downloads=$(echo "$response" | jq '.stats.version_downloads')
        version_unique_downloads=$(echo "$response" | jq '.stats.version_unique_downloads')
        version_views=$(echo "$response" | jq '.stats.version_views')
        version_unique_views=$(echo "$response" | jq '.stats.version_unique_views')

        # Write the extracted data to CSV
        #echo "Got stats for $doi"
	echo "$doi,$date,$downloads,$unique_downloads,$views,$unique_views,$version_downloads,$version_unique_downloads,$version_views,$version_unique_views" >> "$stats_output_file"
    else
        echo "Failed to fetch data for DOI: $doi"
    fi
done
