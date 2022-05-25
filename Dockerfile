ARG NODE_VERSION

FROM node:$NODE_VERSION-bullseye-slim as node
FROM ubuntu:22.04

# Copy Node modules from Node image
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /opt/ /opt/

ENV TZ=UTC
ENV CHROME_BIN /usr/bin/google-chrome-stable
ENV FIREFOX_BIN /usr/bin/firefox

# Install Chrome, Firefox
# Add Node user for unroot node run
# Test all packages installed works
RUN corepack disable && corepack enable && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && apt update -y && apt-get upgrade -y \
    && apt install -y wget gnupg git curl build-essential unzip wget bzip2 \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
    && apt update -y && apt install -y firefox google-chrome-stable \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node \
    && node --version \
    && npm --version \
    && yarn --version