# Base stage: Install dependencies
FROM ubuntu:jammy AS base

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Set working directory inside the container
WORKDIR /usr/src/app

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG en_US.UTF-8

# Set environment variables to prevent Python from writing .pyc files and buffering stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Update package lists, install CA certificates, reconfigure them, and add the new mirror in one step
RUN apt-get update && apt-get install -y ca-certificates && \
    update-ca-certificates && \
    sed -i '1ideb https://mirror.twds.com.tw/ubuntu/ jammy main restricted universe multiverse' /etc/apt/sources.list && \
    sed -i '1ideb https://mirror.twds.com.tw/ubuntu/ jammy-updates main restricted universe multiverse' /etc/apt/sources.list && \
    sed -i '1ideb https://mirror.twds.com.tw/ubuntu/ jammy-backports main restricted universe multiverse' /etc/apt/sources.list && \
    sed -i '1ideb https://mirror.twds.com.tw/ubuntu/ jammy-security main restricted universe multiverse' /etc/apt/sources.list

# Install dependencies for building Python packages and Odoo dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    zlib1g-dev \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libldap2-dev \
    libsasl2-dev \
    libjpeg-dev \
    libblas-dev \
    libatlas-base-dev \
    libssl-dev \
    libffi-dev \
    libfreetype6-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libxcb1-dev \
    libwebp-dev \
    libx11-6 \
    libxext6 \
    libxrender1 \
    xfonts-75dpi \
    xfonts-base \
    pkg-config \
    git \
    curl \
    dirmngr \
    fonts-noto-cjk \
    gnupg \
    node-less \
    npm \
    xz-utils \
    fontconfig \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

RUN if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=967390a759707337b46d1c02452e2bb6b2dc6d59  ;; \
    "arm64")  WKHTMLTOPDF_SHA=90f6e69896d51ef77339d3f3a20f8582bdf496cc  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=5312d7d34a25b321282929df82e3574319aed25c  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Poetry using pip
RUN pip install poetry

# Copy only pyproject.toml and poetry.lock for dependency installation
COPY ./pyproject.toml ./poetry.lock ./

# Install project dependencies using Poetry
RUN poetry config virtualenvs.create false && poetry install --no-root


# Final stage: Set up Odoo
FROM base AS final

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Copy local Odoo source code and addons to the image
# Copy entrypoint script and Odoo configuration file
COPY ./odoo /usr/src/app/odoo
COPY ./addons /opt/odoo/addons
COPY ./odoo.conf /etc/odoo/
COPY ./check-db-status.py /usr/local/bin/
COPY ./entrypoint.sh /
WORKDIR /usr/src/app/odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
