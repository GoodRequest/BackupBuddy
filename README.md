# <img align="left" width="40" height="40" alt="GoodRequest, s.r.o." src="./favicon.png">Backup Buddy

### _Simple Bash app for backing up your precious data made with love 🫶_

___ 

## Currently supported features

### 🤔 WHAT to backup ?

__1. PostgreSQL, MongoDB, MySQL__ - If you choose this option, don't forget to __provide connection details__. Also make sure your __database is reachable from within this container__.

__2. Filesystem directory__ - If you choose this option, don't forget to __attach volume__ to this container, so Backup Buddy __can access__ these files.

### 📍 WHERE to backup ?

__1. AWS S3 Bucket__ - If you choose this option, you'll have to create custom __IAM User__ (_generate access keys_) and __S3 Bucket__ (_add bucket policy_).

__2. Filesystem__ - If you choose this option don't forget to __attach volume__ to your container, so backups are __stored on physical disk__ and are __persistent__.

### 📊 Monitoring

If you want to make sure that backups are being correctly created, consider using __monitoring tool__ such as __[Uptime Robot](https://uptimerobot.com/)__. You can then pass generated URL into the Backup Buddy through __HEARTBEAT_URL__ env variable, where it will be pinged each time a __non-zero size__ (_not corrupted_) backup is created. This way you can be __easily alerted__ if backups are not being created.

### 🗂️ Compression

To achieve smallest size possible, __Backup Buddy uses compression__ so your backups don't bloat out your disk.

### 🔧 Custom pg_dump options

If you want to pass custom options into the __pg_dump__ command, you can easily do so by using the __PG_DUMP_CUSTOM_OPTIONS__ env variable. Just make sure that __you know what you are doing__, since in this case we trust your input (_no sanitization is at play here_).

### 📝 Debug logging

If you want to make sure you container has been set-up and/or is working properly, enable __debug logging__. This will __print logs into stdout__ during setup phase (_installation of required packages_) and __into the file__ on path you specified in __LOG_DIR__ during the run phase (_worker runs triggered by cron rule_).

___

## A (Very) Quick Start

Deploy the app in a Docker Compose stack with environment variables satisfying your needs.

Once deployed, app will setup its worker and will start the backuping process within its next cron run.

___

## Database Dump-Restore pairs

### <img align="left" width="30" height="30" alt="PostgreSQL" src="https://wiki.postgresql.org/images/9/9a/PostgreSQL_logo.3colors.540x557.png"> PostgreSQL

```
pg_dump -U <username> -h <host> -p <port> -d <database> -f <dump file> -O -x -Fc
```

```
pg_restore -U <username> -h <host> -p <port> -d <database> <dump file> -O -c -v -x -j <number of threads>
```

### <img align="left" width="30" height="30" alt="MongoDB" src="https://www.svgrepo.com/show/331488/mongodb.svg"> MongoDB

```
mongodump -h <host> -d <database> -u <username> -p <password> -o <destination>
```

```
mongorestore -h <host> -u <username> -p <password> --authenticationDatabase admin -d <database> <destination>/<database>
```

### <img align="left" width="30" alt="MySQL" src="https://www.mysql.com/common/logos/logo-mysql-170x115.png"> MySQL

```
mysqldump -h <host> -P <port> -u <username> <database> --result-file=<filename> --ssl-mode=disabled
```

```
mysql -h <host> -P <port> -u <username> <database> -p -v < <dump file>
```

___

## Configuration

Configuration of tool can be done through ENV variables described in table below (**_there is also built in variable validator to prevent mistakes_**):

| ENV Variable                   | Required       | Description     | Example     | Default        |
| -------------------------------|:--------------:|-----------------|-------------|----------------|
| **TYPE**                       | ✅             | Type of backup system (currently supported MONGO, POSTGRE, MYSQL, FILESYSTEM) | MONGO | |
| **HOST**                       | ✅             | URL or IP address of database (be sure you have allowed connection from container), also can be container name (if is ran in Rancher/Docker-Compose stack) | postgresql.goodrequest.com | |
| **DATABASE**                   | ✅             | Name of database | goodrequest | |
| **USER**                       | ✅             | User name for database | postgres | |
| **PASSWORD**                   | ✅             | User password for database | UnitedLikeManchester123. | |
| **TARGET_DIR**                 | ✅             | Absolute path to directory (mounted in Backup Buddy container) where backups will be stored | /home/backup | |
| **FILESYSTEM_DIR**             | ✅             | Absolute path to directory (mounted in Backup Buddy container) which should be backed up | /home/files | |
| **CRON_RULE**                  | ✅             | Cron rule definition - when or how often will be created database backup (https://crontab.guru/) (in example each 8 hours) | 0 */8 * * * | |
| **KEEP_DAYS**                  | ✅             | How many days will be stored backups, older backups will be automatically removed | 30 | |
| **TARGET_TYPE**                | ❌             | Target for backups to be saved to (currently supported FILESYSTEM, AWS_S3) | AWS_S3 | FILESYSTEM |
| **AWS_ACCESS_KEY_ID**          | ❌             | Access key ID for AWS S3 (required when TARGET_TYPE is set to AWS_S3) | somerandomawsacceskey | |
| **AWS_SECRET_ACCESS_KEY**      | ❌             | Secret access key for AWS S3 (required when TARGET_TYPE is set to AWS_S3) | somerandomawssecretaccesskey | |
| **AWS_REGION**                 | ❌             | Region for AWS S3 (required when TARGET_TYPE is set to AWS_S3) | eu-central-1 | |
| **BUCKET_NAME**                | ❌             | Bucket name for AWS S3 (required when TARGET_TYPE is set to AWS_S3) | test-bucket | |
| **PORT**                       | ❌             | Target port of database container (Currently valid for POSTGRE only). | 5432 | 5432 |
| **HEARTBEAT_URL**              | ❌             | URL for sending notification about successfully created backup (typically specialized monitoring tool like Uptime) | https://example.com/somerandomlygeneratedpath | |
| **DEBUG_LOGGING**              | ❌             | Enables debug logging into console and log file | true | |
| **LOG_DIR**                    | ❌             | Directory for storing logs outputs from backup scripts | /home/logs | |
| **PG_DUMP_CUSTOM_OPTIONS**     | ❌             | Custom options to pass into pg_dump command | --schema-only | |

___

## Additional Resources

<img align="left" width="25" height="25" alt="Docker" src="https://www.docker.com/wp-content/uploads/2023/04/cropped-Docker-favicon-32x32.png">[**Docker**](https://www.docker.com) documentation is available [here](https://docs.docker.com).

<img align="left" width="25" height="25" alt="Bash" src="https://bashlogo.com/img/symbol/png/full_colored_light.png">[**Bash**](https://www.gnu.org/software/bash/) documentation is available [here](https://www.gnu.org/software/bash/manual/).

<img align="left" width="25" height="25" alt="PostgreSQL" src="https://wiki.postgresql.org/images/9/9a/PostgreSQL_logo.3colors.540x557.png">[**PostgreSQL**](https://www.postgresql.org/) documentation is available [here](https://www.postgresql.org/docs/).

<img align="left" width="25" height="25" alt="MongoDB" src="https://www.svgrepo.com/show/331488/mongodb.svg">[**MongoDB**](https://www.mongodb.com/) documentation is available [here](https://www.mongodb.com/docs/).

<img align="left" width="25" alt="MySQL" src="https://www.mysql.com/common/logos/logo-mysql-170x115.png">[**MySQL**](https://www.mysql.com/) documentation is available [here](https://dev.mysql.com/doc/).

___

## License

**Backup Buddy** is released under the MIT license. See [LICENSE.md](./LICENSE.md) for details.
