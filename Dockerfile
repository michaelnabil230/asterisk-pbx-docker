FROM debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV ASTERISK_VERSION=23.4.0

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    build-essential \
    pkg-config \
    autoconf \
    automake \
    libtool \
    bison \
    flex \
    uuid-dev \
    libxml2-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libjansson-dev \
    libssl-dev \
    libedit-dev \
    libsrtp2-dev \
    libopus-dev \
    libogg-dev \
    libcurl4-openssl-dev \
    unixodbc \
    unixodbc-dev \
    libmariadb3 \
    mariadb-plugin-connect \
    odbc-mariadb \
    mariadb-client \
    odbcinst \
    default-libmysqlclient-dev \
    python3 \
    python3-pip \
    python3-venv

RUN rm -rf /var/lib/apt/lists/*

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

RUN python3 -m venv /opt/venv

RUN /opt/venv/bin/pip install \
    alembic \
    sqlalchemy \
    pymysql

ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /usr/src

RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-${ASTERISK_VERSION}.tar.gz

RUN tar -xzf asterisk-${ASTERISK_VERSION}.tar.gz

WORKDIR /usr/src/asterisk-${ASTERISK_VERSION}

RUN ./configure

RUN make menuselect.makeopts

RUN menuselect/menuselect \
    --enable app_audiosocket \
    --enable res_odbc \
    --enable res_http_websocket \
    --enable res_pjsip \
    --enable res_pjsip_transport_websocket \
    menuselect.makeopts

RUN make

RUN make install

RUN make samples

# Install ast-db-manage globally

RUN ln -sf \
    /usr/src/asterisk-${ASTERISK_VERSION}/contrib/ast-db-manage/ast-db-manage \
    /usr/local/bin/ast-db-manage

# Create asterisk user and group

RUN groupadd -r asterisk && useradd -r -g asterisk -d /var/lib/asterisk -s /usr/sbin/nologin asterisk

# Create required directories

RUN mkdir -p \
    /var/lib/asterisk \
    /var/log/asterisk \
    /var/run/asterisk \
    /var/spool/asterisk

# Set ownership

RUN chown -R asterisk:asterisk  \
    /var/lib/asterisk  \
    /var/log/asterisk  \
    /var/run/asterisk  \
    /var/spool/asterisk  \
    /etc/asterisk 

EXPOSE 5060/udp 5060/tcp 5061/tcp 8088/tcp 8089/tcp 10000-10199/udp

ENTRYPOINT ["/docker-entrypoint.sh"]