#!/bin/bash


/opt/kafka/bin/kafka-configs.sh --bootstrap-server 127.0.0.1:9092 --alter --entity-type topics --entity-name test-humio-ingest --add-config retention.bytes=41666666700

/opt/kafka/bin/kafka-configs.sh --zookeeper 127.0.0.1:2181 --entity-name humio-ingest --entity-type topics --describe

/opt/kafka/bin/kafka-configs.sh --zookeeper 127.0.0.1:2181 --entity-name humio-ingest --entity-type topics --alter --add-config retention.ms=604800000

/opt/kafka/bin/kafka-configs.sh --zookeeper 127.0.0.1:2181 --entity-name humio-ingest --entity-type topics --alter --add-config retention.bytes=1073741824

# Set protocol version for topic:
/opt/kafka/bin/kafka-configs.sh --zookeeper 127.0.0.1:2181 --alter --entity-type topics --entity-name 'humio-ingest' --add-config 'message.format.version=0.11.0'

# Remove setting, allowing to use the default of the broker:
/opt/kafka/bin/kafka-configs.sh --zookeeper 127.0.0.1:2181 --alter --entity-type topics --entity-name 'humio-ingest' --delete-config 'message.format.version'