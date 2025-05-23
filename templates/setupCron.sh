#!/bin/bash
echo "Starting node-cron"

if [ -z "$TASK_SCHEDULE" ]; then
    TASK_SCHEDULE='* * * * *'
fi
echo "TASK_SCHEDULE => $TASK_SCHEDULE"


if [ -z "$NPM_COMMAND" ]; then
    NPM_COMMAND='start'
fi
export NPM_COMMAND=$NPM_COMMAND
echo "yarn $NPM_COMMAND"


env                                           >> /tmp/.env
cat /tmp/.env                                 >> /etc/cron.d/my-cron-job
echo -n "$TASK_SCHEDULE" | cat - /tmp/crontab >> /etc/cron.d/my-cron-job


echo "Running cron"
cron && tail -f /var/log/cron.log