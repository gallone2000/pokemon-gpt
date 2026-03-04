# Hello World FastAPI + Nix (no pip/venv)

This repository is a **very small FastAPI application** written in Python.

Instead of the more common approach:

- using `pip` to install dependencies into a virtual environment (`.venv`), and
- building from an official Python image like `python:3.14`

…this project uses **Nix** (via a `flake.nix`) to provide **Python and all Python dependencies** from **nixpkgs**.

That means:

- no `pip install` / no `uv sync` / no `.venv`
- the dependency set is defined in `flake.nix` and pinned by `flake.lock`
- Docker images can run on a minimal base (e.g. distroless) by copying only the required Nix store closure

---

## What’s inside

### API endpoints

- `GET /` → returns `{"message": "Hello World"}`
- `GET /hello/{name}` → returns `{"message": "Hello {name}" }`
- `GET /health` → returns `{"status": "ok"}`

### Main file

The application lives in `main.py` and exposes `app`, so Uvicorn runs it as:

- `main:app`

---

## Requirements

- **Nix** with flakes enabled (modern Nix)
- Optional: Docker (for container builds)

---

## Run locally (development)

Enter the Nix development shell:

```bash
nix develop
```

Sanity check:

```bash
python -c "import fastapi, uvicorn; print('ok')"
```

Run the server:

```bash
python -m uvicorn main:app --reload
```

Open:

- http://127.0.0.1:8000/
- http://127.0.0.1:8000/hello/Alice
- http://127.0.0.1:8000/health

---

## How dependencies work (important)

Dependencies are **not** installed via `pip`.

They are declared in `flake.nix` using nixpkgs Python packages, for example:

- `pkgs.python314Packages.fastapi`
- `pkgs.python314Packages.uvicorn`

Nix then builds a Python environment (often called `pyEnv`) with:

```nix
python.withPackages (ps: with ps; [
  fastapi
  uvicorn
])
```

The exact nixpkgs revision is pinned by `flake.lock`.

---

## Docker (optional)

This project can be containerized without relying on `python:3.14` images.

A typical pattern is:

1. Build the Nix Python environment in a `nixos/nix` builder stage
2. Copy the minimal required `/nix/store` closure + app sources
3. Run on a small runtime image (e.g. distroless)

Example run command (after building your image):

```bash
docker run --rm -p 8000:8000 <your-image-name>
```

---

## Notes

- If you see: `warning: Git tree is dirty`  
  Nix is just warning that you have uncommitted changes. It does not break anything.
