
FROM node:latest

## install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

## install packages
RUN apt-get update \
    && apt-get install -y git cron yarn nano --no-install-recommends && rm -rf /var/lib/apt/lists/*

COPY ./templates/log-rotation /etc/logrotate.d/my-cron-job
COPY ./templates/crontab /tmp/crontab
COPY ./templates/setupCron.sh /tmp/setupCron.sh

RUN touch /etc/cron.d/my-cron-job
RUN chmod 0644 /etc/cron.d/my-cron-job
RUN touch /var/log/cron.log

RUN chmod +x /tmp/setupCron.sh

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
RUN yarn install

CMD ["/tmp/setupCron.sh"]