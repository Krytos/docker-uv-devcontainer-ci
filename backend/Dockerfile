FROM python:3.13-slim-bookworm AS base

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# ---- ENVIRONMENT VARIABLES ----
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/.venv/bin:$PATH" \
    VIRTUAL_ENV="/.venv" \
    PYTHONPATH="/app:/.venv:$PYTHONPATH" \
    UV_CACHE_DIR="/opt/uv-cache" \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1

RUN --mount=type=cache,target=/opt/uv-cache

# ---------------------
# ---- BUILD STAGE ----
# ---------------------

FROM base AS builder

# ---- BUILD-ESSENTIALS ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ---- CACHE AND UV CONFIGURATION ----
WORKDIR /

COPY pyproject.toml ./
ADD uv.lock* ./

RUN uv sync --no-dev

COPY backend /app


# ---------------------
# ----- DEV STAGE -----
# ---------------------
FROM base AS development

# ---- DEVELOPMENT-ESSENTIALS ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sudo \
    wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m devuser && \
    echo "devuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devuser && \
    chmod 0440 /etc/sudoers.d/devuser

COPY --chown=devuser:devuser --from=builder /.venv /.venv
COPY --chown=devuser:devuser --from=builder /app /app
COPY --chown=devuser:devuser --from=builder pyproject.toml uv.lock ./

RUN uv sync --dev

RUN chown -R devuser:devuser /opt/uv-cache

USER devuser

WORKDIR /app

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# ----------------------
# ----- PROD STAGE -----
# ----------------------

FROM base AS production

RUN apt-get update --yes --quiet && apt-get install htop nodejs melt python3-mlt frei0r-plugins bs2b-ladspa npm libpq-dev --yes --quiet --no-install-recommends && apt-cache search ladspa | grep plugins
RUN apt-get install --fix-missing -y xvfb

COPY --chown=prod_user:prod_user --from=builder /.venv /.venv
COPY --chown=prod_user:prod_user --from=builder /app /app

RUN useradd -m prod_user && \
    chmod -R ugo-w /app

USER prod_user

WORKDIR /app

CMD set -xe; python manage.py collectstatic --noinput --clear; daphne -b 0.0.0.0 -p 8000 PROJECT_NAME.asgi:application
