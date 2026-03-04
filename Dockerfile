# syntax=docker/dockerfile:1.6

FROM nixos/nix:2.34.0@sha256:b9c9611c8530fa8049a1215b20638536e1e71dcaf85212e47845112caf3adeea AS builder
WORKDIR /app

RUN mkdir -p /etc/nix && \
    printf "experimental-features = nix-command flakes\n" >> /etc/nix/nix.conf

# flake first for caching
COPY flake.nix flake.lock ./

# build the python env from nixpkgs
RUN nix build .#pyEnv --out-link /tmp/pyenv

# now copy the app
COPY . .

# collect closure for the env (everything needed under /nix/store)
RUN set -eux; \
  ENV_PATH="$(readlink -f /tmp/pyenv)"; \
  echo "pyEnv: $ENV_PATH"; \
  nix-store -qR "$ENV_PATH" > /tmp/nix-closure.txt; \
  mkdir -p /tmp/nix-store; \
  xargs -a /tmp/nix-closure.txt -I{} cp -a {} /tmp/nix-store/

# ---- runtime ----
FROM gcr.io/distroless/base-debian13:nonroot@sha256:e00da4d3bd422820880b080115b3bad24349bef37ed46d68ed0d13e150dc8d67
WORKDIR /app

# bring in nix store closure + a stable symlink /pyenv -> /nix/store/...-python3-...
COPY --from=builder /tmp/nix-store/ /nix/store/
COPY --from=builder /tmp/pyenv /pyenv

# app sources
COPY --from=builder /app /app

EXPOSE 8000
CMD ["/pyenv/bin/python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]