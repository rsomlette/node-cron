FROM node:23-slim

# Environment variables
ENV NODE_ENV=production
ENV CRON_LOG_LEVEL=info

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Node.js Cron Job Container"
LABEL version="1.0"

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install necessary runtime dependencies (cron, tini, yarn)
# Use modern key import method for Yarn
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    cron \
    nano \
    tini \
    gnupg \
    ca-certificates \
    procps \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends yarn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY ./templates/log-rotation /etc/logrotate.d/my-cron-job
COPY ./templates/crontab /tmp/crontab
COPY ./templates/setupCron.sh /tmp/setupCron.sh

# Set up initial cron file/permissions and make setup script executable
# The setup script will overwrite /etc/cron.d/my-cron-job later
RUN touch /var/log/cron.log \
    && touch /etc/cron.d/my-cron-job \
    && chmod 0644 /etc/cron.d/my-cron-job \
    && chmod +x /tmp/setupCron.sh

# Set up application directory
WORKDIR /app

# Healthcheck with better cron process verification
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ps aux | grep '[c]ron' || exit 1

# Use tini for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/tmp/setupCron.sh"]