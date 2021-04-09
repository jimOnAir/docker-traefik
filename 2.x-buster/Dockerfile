ARG DEBIAN_VERSION=buster
FROM debian:${DEBIAN_VERSION}

ARG APT_PROXY=
ARG S6_VERSION=v2.2.0.3
ARG TRAEFIK_VERSION=v2.4.8

ENV LANG en_US.utf8

RUN set -ex; \
  # enable APT_PROXY if it has been specified
  if [ -n "${APT_PROXY}" ];then \
    echo "Acquire::http { Proxy \"${APT_PROXY}\"; };" > /etc/apt/apt.conf.d/01proxy; \
  fi; \
  # see note below about "*.pyc" files
  export PYTHONDONTWRITEBYTECODE=1; \
  DEBIAN_FRONTEND="noninteractive" apt-get -yyq update; \
  DEBIAN_FRONTEND="noninteractive" apt-get -yyq install --no-install-recommends\
		nginx \
    apt-transport-https\
    ca-certificates \
    curl \
    dateutils \
    dirmngr \
    gnupg \
    locales \
    lsb-release \
    procps \
    ; \
  DEBIAN_FRONTEND="noninteractive" apt-get clean; \
  rm -rf /var/lib/apt/lists/*; \
  locale-gen en_US.UTF-8; \
  localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8; \
  update-ca-certificates; \
  sed -i 's|^CREATE_MAIL_SPOOL=yes|CREATE_MAIL_SPOOL=no|g' /etc/default/useradd; \
  curl -sSL https://keybase.io/justcontainers/key.asc | gpg --import; \
  export TMPDIR="$(mktemp -d)"; \
  export ARCH="$(dpkg --print-architecture)"; \
  curl -sSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${ARCH}.tar.gz" \
    -o  "${TMPDIR}/s6-overlay-${ARCH}.tar.gz"; \
  curl -sSL "https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${ARCH}.tar.gz.sig" \
    -o "${TMPDIR}/s6-overlay-${ARCH}.tar.gz.sig"; \
  gpg --verify "${TMPDIR}/s6-overlay-${ARCH}.tar.gz.sig" "${TMPDIR}/s6-overlay-amd64.tar.gz"; \
  tar zxf "${TMPDIR}/s6-overlay-${ARCH}.tar.gz" -C /; \
  rm -rf "${TMPDIR}"; \
  echo "disable-ipv6" >> /root/.gnupg/dirmngr.conf;\
  rm -rf /var/www/html /etc/nginx/sites-enabled/default; \
  mkdir -p /var/www/html; \
	# some of the steps above generate a lot of "*.pyc" files (and setting "PYTHONDONTWRITEBYTECODE" beforehand doesn't propagate properly for some reason), so we clean them up manually (as long as they aren't owned by a package)
	find /usr -name '*.pyc' -type f -exec bash -c 'for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done' -- '{}' +; \
  # disable APT_PROXY if it has been specified
  if [ -n "${APT_PROXY}" ];then \
    rm /etc/apt/apt.conf.d/01proxy; \
  fi

COPY root /

RUN set -ex; \
  mkdir -p /usr/local/bin/; \
  curl -sSL "https://github.com/containous/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_linux_amd64.tar.gz" | \
    tar -zxf - -C "/usr/local/bin/" traefik

ENTRYPOINT [ "/init" ]
CMD ["/usr/local/bin/traefik"]
