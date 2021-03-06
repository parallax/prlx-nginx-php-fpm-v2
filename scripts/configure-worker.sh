#!/bin/bash
printf "Copying configuration to writeable folder\n"
cp -R /etc/config/read/* /etc/config/write/

# printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Key" "Value"

# Container info:
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Site:" "$SITE_NAME"
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Branch:" "$SITE_BRANCH"
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Environment:" "$ENVIRONMENT"

# Atatus - if api key is set then configure and enable
if [ ! -z "$ATATUS_APM_LICENSE_KEY" ] && [ "$ATATUS_APM_LICENSE_KEY" != "test" ]; then

    # Enabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Atatus:" "Enabled"

    # Set the atatus api key
    sed -i -e "s/atatus.license_key = \"\"/atatus.license_key = \"$ATATUS_APM_LICENSE_KEY\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the release stage to be the environment
    sed -i -e "s/atatus.release_stage = \"production\"/atatus.release_stage = \"$ENVIRONMENT\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the app name to be site_name environment
    sed -i -e "s/atatus.app_name = \"PHP App\"/atatus.app_name = \"$SITE_NAME\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the app version to be the branch build
    sed -i -e "s/atatus.app_version = \"\"/atatus.app_version = \"$SITE_BRANCH-$BUILD\"/g" /etc/config/write/php/conf.d/atatus.ini

    # Set the tags to contain useful data
    sed -i -e "s/atatus.tags = \"\"/atatus.tags = \"$SITE_BRANCH-$BUILD, $SITE_BRANCH\"/g" /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - if api key is not set then disable
if [ -z "$ATATUS_APM_LICENSE_KEY" ] && [ "$ATATUS_APM_LICENSE_KEY" != "test" ]; then

    # Disabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Atatus:" "Disabled"
    rm -f /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - configure raw sql logs if desirable
if [ ! -z "$ATATUS_APM_RAW_SQL" ]; then

    # Enabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Atatus SQL:" "Raw"

    # Set the atatus api key
    sed -i -e "s/atatus.sql.capture = \"normalized\"/atatus.sql.capture = \"raw\"/g" /etc/config/write/php/conf.d/atatus.ini

fi

# Atatus - configure laravel queues if desirable
if [ ! -z "$ATATUS_APM_LARAVEL_QUEUES" ]; then

    # Enabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Atatus Laravel Queues:" "Yes"

    # Set the atatus api key
    sed -i -e "s/atatus.laravel.enable_queues = false/atatus.laravel.enable_queues = true/g" /etc/config/write/php/conf.d/atatus.ini

fi

php -r 'echo "";'

# Version numbers:
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Version:" "`php -r 'echo phpversion();'`"
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Nginx Version:" "`/usr/sbin/nginx -v 2>&1 | sed -e 's/nginx version: nginx\///g'`"

# PHP Max Memory
# If set
if [ ! -z "$PHP_MEMORY_MAX" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#memory_limit = 128M#memory_limit = ${PHP_MEMORY_MAX}M#g" /etc/config/write/php/php.ini

fi

# Print the real value
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Memory Max:" "`php -r 'echo ini_get("memory_limit");'`"

# PHP Opcache
# If not set
if [ -z "$DISABLE_OPCACHE" ]; then
    
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Opcache:" "Enabled"

fi
# If set
if [ ! -z "$DISABLE_OPCACHE" ]; then
    
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Opcache:" "Disabled"
    
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.enable=1#opcache.enable=0#g" /etc/config/write/php/php.ini
    sed -i -e "s#opcache.enable_cli=1#opcache.enable_cli=0#g" /etc/config/write/php/php.ini

fi

# PHP Opcache Memory
# If set
if [ ! -z "$PHP_OPCACHE_MEMORY" ]; then
    
    # Set PHP.ini accordingly
    sed -i -e "s#opcache.memory_consumption=16#opcache.memory_consumption=${PHP_OPCACHE_MEMORY}#g" /etc/config/write/php/php.ini

fi

# Print the real value
printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Opcache Memory Max:" "`php -r 'echo ini_get("opcache.memory_consumption");'`M"

# PHP Session Config
# If set
if [ ! -z "$PHP_SESSION_STORE" ]; then
    
    # Figure out which session save handler is in use, currently only supports redis
    if [ $PHP_SESSION_STORE == 'redis' ] || [ $PHP_SESSION_STORE == 'REDIS' ]; then
        if [ -z $PHP_SESSION_STORE_REDIS_HOST ]; then
            PHP_SESSION_STORE_REDIS_HOST='redis'
        fi
        if [ -z $PHP_SESSION_STORE_REDIS_PORT ]; then
            PHP_SESSION_STORE_REDIS_PORT='6379'
        fi
        printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Sessions:" "Redis"
        printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Redis Host:" "$PHP_SESSION_STORE_REDIS_HOST"
        printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "PHP Redis Port:" "$PHP_SESSION_STORE_REDIS_PORT"
        sed -i -e "s#session.save_handler = files#session.save_handler = redis\nsession.save_path = \"tcp://$PHP_SESSION_STORE_REDIS_HOST:$PHP_SESSION_STORE_REDIS_PORT\"#g" /etc/config/write/php/php.ini
    fi

fi

# Enable short tags for older sites
if [ ! -z "$PHP_ENABLE_SHORT_TAGS" ]; then
    sed -i -e 's/short_open_tag = Off/short_open_tag = On/g' /etc/config/write/php/php.ini
fi

# Cron
# If DISABLE_CRON is set:
if [ ! -z "$DISABLE_CRON" ]; then

    # Disabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Cron:" "Disabled"

fi

# If not set, enable monitoring:
if [ -z "$DISABLE_CRON" ]; then

    # Enabled
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Cron:" "Enabled"

    cp /etc/supervisor.d/cron.conf /etc/config/write/supervisord-enabled/

fi

# Set SMTP settings
if [ "$ENVIRONMENT" == 'production' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.smtp-production
    fi

    if [ -z "$MAIL_PORT" ]; then
        export MAIL_PORT=25
    fi

fi

if [ "$ENVIRONMENT" == 'qa' ]; then
    
    if [ -z "$MAIL_HOST" ]; then
        export MAIL_HOST=master-smtp.mailhog-production
    fi
fi

if [ -z "$MAIL_DRIVER" ]; then
    export MAIL_DRIVER=mail
fi

if [ -z "$MAIL_PORT" ]; then
    export MAIL_PORT=25
fi

printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "SMTP:" "$MAIL_HOST:$MAIL_PORT"
sed -i -e "s#sendmail_path = /usr/sbin/sendmail -t -i#sendmail_path = /usr/sbin/sendmail -t -i -S $MAIL_HOST:$MAIL_PORT#g" /etc/config/write/php/php.ini

# Startup scripts
if [ -f /startup-all.sh ]; then
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Startup Script:" "Running"
    mkdir -p /etc/config/write/scripts
    cp /startup-all.sh /etc/config/write/scripts/
    chmod +x /etc/config/write/scripts/startup-all.sh
    /etc/config/write/scripts/startup-all.sh
fi

if [ -f /startup-worker.sh ]; then
    printf "\e[94m%-30s\e[0m \e[35m%-30s\e[0m\n" "Worker Startup Script:" "Running"
    mkdir -p /etc/config/write/scripts
    cp /startup-worker.sh /etc/config/write/scripts/
    chmod +x /etc/config/write/scripts/startup-worker.sh
    /etc/config/write/scripts/startup-worker.sh
fi

# Enable the worker-specific supervisor files
cp /etc/supervisord-worker/* /etc/config/write/supervisord-enabled/