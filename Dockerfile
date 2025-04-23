FROM node:23-slim

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install yarn and required packages in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    cron \
    nano \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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

# Set proper permissions
RUN chown -R appuser:appuser /usr/src/app \
    && chown -R appuser:appuser /var/log/cron.log

USER appuser

HEALTHCHECK --interval=30s --timeout=3s \
    CMD ps aux | grep cron | grep -v grep || exit 1

CMD ["/tmp/setupCron.sh"]