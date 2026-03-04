# Hello World FastAPI + Nix (no pip/venv)

This repository is a **simple FastAPI application** written in Python.

Instead of the more common approach:

- installing dependencies with `pip` into a virtual environment (`.venv`), and
- building/running from an official Python image like `python:3.14`

…this project uses **Nix** (via a `flake.nix`) to provide **Python and all Python dependencies** from **nixpkgs**.

## Why Nix here?

Using Nix gives you:

- **Reproducibility**: the dependency set is pinned by `flake.lock`, so the same inputs produce the same environment.
- **Fewer surprises across machines**: teammates on different laptops/OSes (and CI) get the same Python + libs, without “works on my machine” drift.
- **No venv management**: no `pip install`, no `uv sync`, no `.venv` to keep in sync.

> **Note about `pyproject.toml`:** it is kept **for informational/documentation purposes only**.
> Dependency management for this project is driven by **`flake.nix` / `flake.lock`**.

---

## What’s inside

### API endpoints

- `GET /` → `{"message": "Hello World"}`
- `GET /hello/{name}` → `{"message": "Hello {name}"}`
- `GET /health` → `{"status": "ok"}`

### Entry point

The application lives in `main.py` and exposes `app`, so Uvicorn runs it as:

- `main:app`

---

## Requirements

- Optional (recommended): **Docker** + **make** (to use the provided Makefile commands)
- Optional: **Nix** (only needed if you want to run the app directly without Docker)

---

## Run locally (recommended: via Docker)

The simplest way to run locally is:

```bash
make start
```

Then open:

- http://127.0.0.1:8000/ (docs: `/docs`, health: `/health`)

Stop it with:

```bash
make stop
```

Health check:

```bash
make health
```

For the full list of targets and variables:

```bash
make help
```

---

## Run locally (without Docker)

If you prefer to run directly on your machine (no container), you can use Nix to get Python + deps:

```bash
nix develop
python -m uvicorn main:app --reload
```

---

## How dependencies work

Dependencies are **not** installed via `pip`.

They are declared in `flake.nix` using nixpkgs Python packages, for example:

- `pkgs.python314Packages.fastapi`
- `pkgs.python314Packages.uvicorn`

Nix builds a Python environment (often called `pyEnv`) with:

```nix
python.withPackages (ps: with ps; [
  fastapi
  uvicorn
])
```

The exact nixpkgs revision is pinned by `flake.lock`.

---

## Docker (distroless runtime)

This project can be containerized without relying on `python:3.14` images.

A typical pattern is:

1. Build the Nix Python environment in a `nixos/nix` builder stage
2. Copy the minimal required `/nix/store` closure + app sources
3. Run on a small runtime image (e.g. distroless)

---

## Makefile (common commands)

Start the service (builds the image first):

```bash
make start
```

Stop the service:

```bash
make stop
```

Health check:

```bash
make health
```

Full list:

```bash
make help
```
