ARG NODE_VERSION

FROM node:$NODE_VERSION-bullseye-slim as node
FROM ubuntu:22.04

ENV TZ=UTC
ENV CHROME_BIN /usr/bin/google-chrome-stable
ENV FIREFOX_BIN /usr/bin/firefox

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ARG FIREFOX_VERSION=latest
ENV MOZ_HEADLESS=1

# Copy Node modules from Node image
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /opt/ /opt/

# Install Chrome, Firefox
# Add Node user for unroot node run
# Test all packages installed works
RUN corepack disable && corepack enable && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt update -y && apt-get upgrade -y \
    && apt install -y wget gnupg git curl build-essential unzip bzip2 libdbus-glib-1-2 libpci3 \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt update -y && apt install -y google-chrome-stable \
    && FIREFOX_DOWNLOAD_URL=$(if [ $FIREFOX_VERSION = "latest" ] || [ $FIREFOX_VERSION = "nightly-latest" ] || [ $FIREFOX_VERSION = "devedition-latest" ]; then echo "https://download.mozilla.org/?product=firefox-$FIREFOX_VERSION-ssl&os=linux64&lang=en-US"; else echo "https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2"; fi) \
    && wget --no-verbose -O /tmp/firefox.tar.bz2 $FIREFOX_DOWNLOAD_URL \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
    && rm /tmp/firefox.tar.bz2 \
    && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
    && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox \
    && firefox -CreateProfile "headless /moz-headless"  -headless \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node \
    && node --version \
    && npm --version \
    && yarn --version \
    && google-chrome --version \
    && firefox --version