FROM node:8-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends xz-utils git python build-essential \
    && apt-get install -y --no-install-recommends ca-certificates apt-transport-https \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list \
    && apt update \
    && apt-get install -y --no-install-recommends php7.2 \
    && apt-get install -y --no-install-recommends php7.2-cli php7.2-curl php7.2-json php7.2-mbstring \
    && curl -s -o composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

WORKDIR /home/theia
ADD package.json ./package.json
ADD plugins plugins

RUN yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=14096" yarn theia build && \
    export THEIA_DEFAULT_PLUGINS=local-dir:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    rm -rf ./node_modules/electron && \
    yarn cache clean


FROM node:8-slim
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG TZ="Europe/Bratislava"
ARG LOCALE="en_US.UTF-8"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sudo \
        git \
        ssh \
        python \
        locales \
        apt-transport-https \
        lftp \
        ca-certificates \
        nano \
    && wget -q https://packages.sury.org/php/apt.gpg -O- | apt-key add - \
    && echo "deb https://packages.sury.org/php/ jessie main" | tee /etc/apt/sources.list.d/php.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends php7.2 php7.2-cli \
    && curl -s -o composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php \
    # clean
	&& apt-get clean autoclean \
	&& apt-get autoremove --yes \
    && rm -rf /var/lib/{apt,dpkg,cache,log}/

RUN userdel -r -f node \
    && addgroup --gid $GROUP_ID theia \
    && adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID theia \
    && adduser theia sudo \
    && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && chmod g+rw /home \
    && mkdir -p /home/project \
    && mkdir -p /home/theia/.theia \
    && mkdir -p /home/theia/.config \
    && chown -R theia:theia /home/theia \
    && chown -R theia:theia /home/project \
    # timezone
    && rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/$TZ /etc/localtime \
    # locale
    && sed -i 's/^# *\('$LOCALE'\)/\1/' /etc/locale.gen \
    && locale-gen \
    && echo "export LC_ALL="$LOCALE >> /home/theia/.bashrc \
    && echo "export LANG="$LOCALE >> /home/theia/.bashrc \
    && echo "export LANGUAGE="$LOCALE >> /home/theia/.bashrc \
    # install gulp globaly
    && npm install gulp -g

ENV HOME /home/theia
WORKDIR /home/theia
COPY --from=0 --chown=theia:theia /home/theia /home/theia
EXPOSE 3000
ENV SHELL /bin/bash

ENV USE_LOCAL_GIT true
USER theia
RUN cat /dev/zero | ssh-keygen -q -N ""
ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0", "--plugins=local-dir:/home/theia/plugins" ]

