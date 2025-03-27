#!/bin/bash
source /scripts/utils/variables.sh

# Function to find the closest version
find_closest_version() {
    local official_versions=$1
    local target=$2
    local closest=

    for version in $official_versions; do
        if (($(echo "$version <= $target" | bc -l))); then
            closest=$version
        fi
    done

    # If closest is still empty, select the highest version
    if [ -z "$closest" ]; then
        closest=$(echo "$official_versions" | sort -n | tail -n 1)
    fi
    echo "$closest"
}

# Setup environment for Mongo database
mongo_backup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Setting up mongo worker"

    # Preparation of Mongo database installation
    apt-get update && apt-get install -y gnupg wget
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -

    # apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    # printf "deb http://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" >> /etc/apt/sources.list.d/mongodb-org-7.0.list
    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] http://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

    # Installation of Mongo database engine
    apt-get update && apt-get install -y mongodb-org

    # Create crontab definition, ENV variable CRON_RULE must be defined
    printf "$CRON_RULE root /bin/bash /scripts/workers/mongo.sh >> $LOG_DIR/mongo.log 2>&1\n\n" > /etc/cron.d/crontab

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Finished setting up mongo worker"
}

# Setup environment for PostgreSQL database
postgres_backup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Setting up postgres worker"

    # Preparation of PostgreSQL database client installation
    apt-get update && apt-get install -y gnupg wget ca-certificates
    wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    printf "deb http://apt.postgresql.org/pub/repos/apt/ $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d "=" -f 2)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

    apt-get update && apt-get install -y postgresql-client bc

    # Get version of running database
    DATABASE_VERSION=$(PGPASSWORD=$PASSWORD psql -U "$USER" -d "$DATABASE" -p "$PORT" -h "$HOST" -c "SELECT version();" | awk -F ' ' '/PostgreSQL/ {print $2}' | cut -d. -f1,2)

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') PostgreSQL database is running on version: $DATABASE_VERSION"

    # Uninstall the previous version of postgresql-client
    apt-get remove --purge -y postgresql-client
    apt autoremove -y

    # List AND SORT all avalible versions of postgres-client and grab the closest one
    OFFICIAL_VERSIONS=$(apt-cache pkgnames | grep postgresql-client | cut -d- -f3 | grep -E '^[0-9]*\.?[0-9]*$' | sort -Vu)

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Official postgresql-client versions found: $OFFICIAL_VERSIONS"

    CLOSEST_CLIENT_VERSION=$(find_closest_version "$OFFICIAL_VERSIONS" "$DATABASE_VERSION")

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Closest postgresql-client version determined: $CLOSEST_CLIENT_VERSION"

    # Installation of PostgreSQL database engine
    [ -z "$CLOSEST_CLIENT_VERSION" ] && apt-get update && apt-get install -y postgresql-client || apt-get update && apt-get install -y postgresql-client-"$CLOSEST_CLIENT_VERSION"

    # Save connection string with password to pgpass file (https://www.postgresql.org/docs/9.3/static/libpq-pgpass.html) and set correct permissions to created file
    printf "$HOST:$PORT:$DATABASE:$USER:$PASSWORD" > /pgpass
    chmod 600 /pgpass
    chown root:root /pgpass

    # Create crontab definition, ENV variable CRON_RULE must be defined
    printf "PGPASSFILE=/pgpass \n $CRON_RULE root /bin/bash /scripts/workers/postgre.sh >> $LOG_DIR/postgresql.log 2>&1\n\n" > /etc/cron.d/crontab

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Finished setting up postgres worker"
}

# Setup environment for MySQL database
mysql_backup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Setting up mysql worker"

    # Installation of MySQL database engine
    apt-get update && apt-get install -y mysql-client
    apt-get update && apt-get install -y gnupg wget

    # Save connection string with password to configuration file and set correct permissions to created file
    printf "[mysqldump]\nuser = $USER\npassword = $PASSWORD" > ~/.my.cnf
    chmod 600 ~/.my.cnf
    chown root:root ~/.my.cnf

    # Create crontab definition, ENV variable CRON_RULE must be defined
    printf "$CRON_RULE root /bin/bash /scripts/workers/mysql.sh >> $LOG_DIR/mysql.log 2>&1\n\n" > /etc/cron.d/crontab

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Finished setting up mysql worker"
}

filesystem_backup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Setting up filesystem worker"

    # Dowload & INstall wget for heatbeat
    apt-get update && apt-get install -y gnupg wget

    # Create crontab definition, ENV variable CRON_RULE must be defined
    printf "$CRON_RULE root /bin/bash /scripts/workers/filesystem.sh >> $LOG_DIR/filesystem.log 2>&1\n\n" > /etc/cron.d/crontab

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Finished setting up filesystem worker"
}

setup_aws_cli() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Setting up aws cli"

    # Avoid prompts while installing
    export DEBIAN_FRONTEND=noninteractive

    # Download and install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws

    # Ensure AWS CLI is in PATH
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc

    # Unset variable
    unset DEBIAN_FRONTEND

    # Configure AWS CLI
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
    aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
    aws configure set default.region "$AWS_REGION"

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Finished setting up aws cli"
}

# Check all required variables, set defaults if not set and add custom variables
bash /scripts/utils/variables.sh

# Create file with exported ENV variables - will be used in specific script for each database system
printenv | sed 's/^\(.*\)$/\1/g' > /etc/cron.d/env.sh

# Make from composed env and crontab executable file
chmod a+x /etc/cron.d/env.sh
chmod a+x /etc/cron.d/crontab

# Install AWS CLI
if [ "$TARGET_TYPE" = "AWS_S3" ]; then
    setup_aws_cli
fi

# Run specific initialization of environment by required type of backup, ENV variable TYPE must be defined
case "$TYPE" in
    MONGO)
        mongo_backup
        ;;
    POSTGRE)
        postgres_backup
        ;;
    MYSQL)
        mysql_backup
        ;;
    FILESYSTEM)
        filesystem_backup
        ;;
esac

# Run cron on foreground
cron -f
