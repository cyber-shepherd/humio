#!/bin/bash

properties_file="./conf/humio.properties"

# Check if properties file exists
if [ ! -f "$properties_file" ]; then
    echo "Properties file not found. Creating a new one."
    touch "$properties_file"
fi

# Prompt the user for URL details
read -p "Enter Humio URL: " humioUrl
read -p "Enter Kafka URL: " kafkaUrl
read -p "Enter Zk URL: " zkUrl

# Update or add URL details in properties file
sed -i "s|^humioUrl=.*$|humioUrl=$humioUrl|" "$properties_file"
sed -i "s|^kafkaUrl=.*$|kafkaUrl=$kafkaUrl|" "$properties_file"
sed -i "s|^zkUrl=.*$|zkUrl=$zkUrl\n|" "$properties_file"

echo "URL details updated in $properties_file file."
