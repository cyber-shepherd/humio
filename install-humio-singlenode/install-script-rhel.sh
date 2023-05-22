#!/bin/bash


# Reading URLs from file.

while IFS='=' read -r key value
do
    # Remove leading/trailing whitespace
    key=$(echo "$key" | sed 's/^[ \t]*//;s/[ \t]*$//')
    value=$(echo "$value" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Check if the line is not a comment or empty
    if [[ $key != \#* && ! -z $key ]]; then
        # Process the property
        case "$key" in
            humioUrl)
                humioUrl="$value"
                ;;
            kafkaUrl)
                kafkaUrl="$value"
                ;;
            zkUrl)
                zkUrl="$value"
                ;;
            *)
                echo "Unknown property: $key"
                ;;
        esac
    fi
done < ./conf/humio.properties

echo "Using Humio Repo: $humioUrl"
echo "Using Kafka Version: $kafkaUrl"
echo "Using Zookeeper Version: $zkUrl"


# Defining required variables

kafkaVersion=""
zkVersion=""


# Installing missing libraries.

yum install -y wget

# Checking if java is installed or not
if java -version 2>&1 >/dev/null | egrep "openjdk\s+\S+" ; then
        echo "Java installed."
else
        echo "Java NOT installed! Initiating installation"
        sudo yum install -y java-11-openjdk-devel
        if java -version 2>&1 >/dev/null | egrep "openjdk\s+\S+" ; then
                echo "Java installed."
        else
                echo "Java installation failed! Stopping script execution. Manually install Java and restart the script."
                exit 1
        fi
fi


# Create necessary users
if getent passwd humio > /dev/null 2>&1; then
        echo "User humio already exist"
else
        adduser humio --shell=/bin/false --no-create-home --system
    if getent passwd humio > /dev/null 2>&1; then
        echo "User humio created."
    else
        echo "Manually retry this step and rerun the script."
        exit 1
    fi
fi

if getent passwd kafka > /dev/null 2>&1; then
        echo "User kafka already exist"
else
        adduser kafka --shell=/bin/false --no-create-home --system
    if getent passwd kafka > /dev/null 2>&1; then
        echo "User kafka created."
    else
        echo "Manually retry kafka user creation and rerun the script."
        exit 1
    fi
fi

if getent passwd zookeeper > /dev/null 2>&1; then
        echo "User zookeeper already exist"
else
        adduser zookeeper --shell=/bin/false --no-create-home --system
    if getent passwd zookeeper > /dev/null 2>&1; then
        echo "User zookeeper created."
    else
        echo "Manually retry zookeeper user creation and rerun the script."
        exit 1
    fi
fi


# Create necessary directories

mkdir -p /opt/humio /etc/humio/filebeat /var/log/humio /var/humio/data || exit 1
chown humio:humio /opt/humio /etc/humio/filebeat || exit 1
chown humio:humio /var/log/humio /var/humio/data || exit 1

mkdir -p /var/log/kafka /var/kafka-data || exit 1
chown kafka:kafka /var/log/kafka || exit 1
chown kafka:kafka /var/kafka-data || exit 1



# Download Humio Server Files
#read -p "Enter humio tar.gz URL: " humioUrl
wget -nc $humioUrl -O /opt/humio/humioServer.tar.gz
tar -xzf /opt/humio/humioServer.tar.gz -C /opt/humio



# Download Kafka Installation Files

#read -p "Enter kafka tar.gz URL: " kafkaUrl
kafkaVersion=$(basename "$kafkaUrl")
kafkaVersion="${kafkaVersion%.tgz}"

wget -nc $kafkaUrl -O /opt/kafkaServer.tgz
tar -xzf /opt/kafkaServer.tgz -C /opt/
ln -sf /opt/$kafkaVersion /opt/kafka



# Download Zookeeper Installation Files

#read -p "Enter kafka tar.gz URL: " zkUrl
zkVersion=$(basename "$zkUrl")
zkVersion="${zkVersion%.tar.gz}"

wget -nc $zkUrl -O /opt/zkServer.tar.gz
tar -xzf /opt/zkServer.tar.gz -C /opt/
ln -sf /opt/$zkVersion /opt/zookeeper
mkdir -p /var/zookeeper/data
bash -c 'echo 1 > /var/zookeeper/data/myid'


# Copying configuration files

cp ./conf/server.properties /opt/kafka/config/
cp ./conf/server.conf /etc/humio
cp ./conf/humio.service /etc/systemd/system/humio.service
cp ./conf/kafka.service /etc/systemd/system/kafka.service
cp ./conf/zookeeper.service /etc/systemd/system/zookeeper.service
cp ./conf/zoo.cfg /opt/zookeeper/conf/zoo.cfg

# LogScale, Zk, Kafka Ownership Assignment

chown -R humio:humio /opt/humio /etc/humio/filebeat || exit 1
chown -R humio:humio /var/log/humio /var/humio/data || exit 1
chown -R zookeeper:zookeeper /opt/$zkVersion || exit 1
chown -R zookeeper:zookeeper /var/zookeeper/data || exit 1
chown -R kafka:kafka /opt/$kafkaVersion || exit 1
chown kafka:kafka /var/log/kafka || exit 1
chown kafka:kafka /var/kafka-data || exit 1


# Daemon reload & Service Preparation

systemctl daemon-reload

echo "LogScale installation completed. Use systemctl to start humio"

