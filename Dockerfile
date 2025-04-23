FROM node:23-slim

# Environment variables
ENV NODE_ENV=production
ENV CRON_LOG_LEVEL=info

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Node.js Cron Job Container"
LABEL version="1.0"

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install runtime and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    cron \
    nano \
    tini \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY ./templates/log-rotation /etc/logrotate.d/my-cron-job
COPY ./templates/crontab /tmp/crontab
COPY ./templates/setupCron.sh /tmp/setupCron.sh

# Set up cron and permissions
RUN touch /etc/cron.d/my-cron-job \
    && chmod 0644 /etc/cron.d/my-cron-job \
    && touch /var/log/cron.log \
    && chmod +x /tmp/setupCron.sh

# Set up application directory
WORKDIR ${APP_DIR}

# Set proper permissions
RUN chown -R appuser:appuser ${APP_DIR} \
    && chown -R appuser:appuser /var/log/cron.log

USER appuser

# Healthcheck with better cron process verification
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ps aux | grep '[c]ron' || exit 1

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/tmp/setupCron.sh"]