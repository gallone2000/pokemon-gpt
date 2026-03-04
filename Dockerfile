# syntax=docker/dockerfile:1.6

FROM nixos/nix:2.34.0@sha256:b9c9611c8530fa8049a1215b20638536e1e71dcaf85212e47845112caf3adeea AS builder
WORKDIR /app

RUN mkdir -p /etc/nix && \
    printf "experimental-features = nix-command flakes\n" >> /etc/nix/nix.conf

COPY flake.nix flake.lock ./
RUN nix develop .#default -c true

COPY pyproject.toml uv.lock ./

# 1) Download wheels (cache)
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=cache,target=/root/.cache/uv \
    --mount=type=cache,target=/wheels \
    nix develop .#default -c sh -lc '\
      set -e; \
      uv export --format requirements-txt --locked -o /tmp/requirements.txt; \
      python -m pip download --require-hashes -r /tmp/requirements.txt -d /wheels \
    '

# 2) Install offline (needs the same /wheels cache mount)
RUN --mount=type=cache,target=/wheels \
    nix develop .#default -c uv sync \
      --frozen \
      --python python3.14 \
      --python-preference only-system \
      --no-python-downloads \
      --no-index \
      --find-links /wheels

# Sanity check: deps presenti
RUN nix develop .#default -c ./.venv/bin/python -c "import fastapi, uvicorn; print('deps ok')"

COPY . .

# --- collect the closure /nix/store needed for the python of the venv ---
RUN set -eux; \
  PY="$(readlink -f .venv/bin/python)"; \
  echo "Venv python: $PY"; \
  nix-store -qR "$PY" > /tmp/nix-closure.txt; \
  mkdir -p /tmp/nix-store; \
  xargs -a /tmp/nix-closure.txt -I{} cp -a {} /tmp/nix-store/

# ---- runtime: distroless base (NO python entrypoint) ----
FROM gcr.io/distroless/base-debian13:nonroot@sha256:e00da4d3bd422820880b080115b3bad24349bef37ed46d68ed0d13e150dc8d67
WORKDIR /app

# bring in only the necessary store
COPY --from=builder /tmp/nix-store/ /nix/store/

# app + venv
COPY --from=builder /app /app

EXPOSE 8000
CMD ["/app/.venv/bin/python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]