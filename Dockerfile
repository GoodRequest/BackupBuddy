FROM ubuntu:24.04
RUN apt-get update && apt-get install -y cron curl unzip

RUN mkdir /scripts
COPY ./scripts /scripts
RUN chmod -R a+x /scripts

CMD ["/scripts/backuper.sh"]
