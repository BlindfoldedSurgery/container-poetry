ARG PYTHON_VERSION
ARG DEBIAN_VERSION
FROM mirror.gcr.io/python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS base

RUN groupadd --system --gid 500 app
RUN useradd --system --uid 500 --gid app --create-home --home-dir /app -s /bin/bash app

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
      tini \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG APP_VERSION=dev
LABEL org.opencontainers.image.description="Container image with Poetry pre-installed."
LABEL org.opencontainers.image.source="https://github.com/BlindfoldedSurgery/container-poetry"
LABEL org.opencontainers.image.url="https://github.com/BlindfoldedSurgery/container-poetry"
LABEL org.opencontainers.image.version=$APP_VERSION

# renovate: datasource=pypi depName=poetry
ENV POETRY_VERSION=2.1.3

WORKDIR /app
ENTRYPOINT [ "tini", "--", "poetry", "run" ]


# Variant based on the Poetry installer
FROM base AS installer

RUN apt-get update -qq \
    && apt-get install -y --no-install-recommends \
      curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV POETRY_HOME="/opt/poetry"
ENV POETRY_VIRTUALENVS_IN_PROJECT=false
ENV PATH="$POETRY_HOME/bin:$PATH"

RUN curl -sSL https://install.python-poetry.org | python3 -

USER 500


# Variant based on pipx
FROM base AS pipx

USER 500

ENV PATH="${PATH}:/app/.local/bin"

RUN pip install --no-cache-dir --user pipx
RUN pipx install poetry=="${POETRY_VERSION}"

ENV POETRY_VIRTUALENVS_IN_PROJECT=false
