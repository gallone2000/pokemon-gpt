# Pokemon GPT

Pokemon GPT is a small AI playground that combines **LibreChat**, **Ollama**, and a custom **FastMCP** server to let you chat with a local LLM and query live Pokémon data from **PokeAPI**.

The idea is simple:

- **LibreChat** provides the chat UI
- **Ollama** runs the local model
- **pokemon-mcp** exposes Pokémon tools through MCP
- **PokeAPI** is the external data source used by the MCP server

With this setup, the model can answer Pokémon-related questions by calling dedicated tools instead of relying only on its internal knowledge.

## How it works

This repository wires together three main pieces:

1. **LibreChat** as the frontend chat application
2. **Ollama** as the local inference backend
3. **A FastMCP server** that exposes Pokémon tools over HTTP

LibreChat is configured to use an Ollama endpoint and an MCP server named `pokemon`, pointing to `http://pokemon-mcp:8000/mcp` inside Docker Compose.

The MCP server wraps PokeAPI and exposes tools for:

- getting a Pokémon by name or id
- getting species information
- searching Pokémon by partial name
- listing Pokémon by type
- checking type matchups
- retrieving an evolution chain
- comparing two Pokémon

## Project structure

```text
.
├── apps/
│   ├── librechat/
│   │   └── librechat.yaml
│   └── mcp-server/
│       ├── src/pokemon_mcp/
│       │   ├── pokemon_api.py
│       │   ├── schemas.py
│       │   ├── server.py
│       │   └── settings.py
│       └── Dockerfile
├── infra/
│   └── compose/
│       └── docker-compose.yml
└── Makefile
```

## Features

- Local chat experience with LibreChat
- Local LLM execution with Ollama
- MCP integration via FastMCP
- Live Pokémon data fetched from PokeAPI
- Docker Compose setup for the full stack
- Makefile commands for common workflows

## Requirements

Before starting, make sure you have:

- **Docker**
- **Docker Compose**
- **GNU Make**

## Getting started

### 1. Clone the repository

```bash
git clone git@github.com:gallone2000/pokemon-gpt.git
cd pokemon-gpt
```

### 2. Initialize LibreChat environment

This project includes a Make target that prepares the LibreChat `.env` file from the template if it is missing.

```bash
make init
```

### 3. Start the full stack

To build and start everything in the background:

```bash
make up-d
```

To run it in the foreground instead:

```bash
make up
```

### 4. Open the application

Once the stack is up, open:

```text
http://localhost:3080
```

LibreChat is the main entry point of the project.

## Useful Make commands

The root `Makefile` already includes the most useful commands for working with the stack.

```bash
make init        # prepare LibreChat .env from template
make build       # build all Docker services
make up          # start the full stack in foreground
make up-d        # start the full stack in background
make down        # stop the full stack
make down-v      # stop the stack and remove volumes
make restart     # restart everything
make ps          # show running services
make status      # show stack status and URLs
make health      # run quick health checks
make logs        # tail logs for all services
make logs-mcp    # tail Pokémon MCP logs
make logs-ollama # tail Ollama logs
```

To see the full list directly from the project:

```bash
make help
```

## Services

### LibreChat

LibreChat runs on port `3080` and is configured to use:

- an **Ollama** custom endpoint
- the **pokemon** MCP server

### Ollama

Ollama runs on port `11434` and is configured in LibreChat with the model:

- `llama3.1:8b`

### Pokemon MCP server

The MCP server is built with **FastMCP** and exposes its endpoint at:

```text
http://pokemon-mcp:8000/mcp
```

Inside the Docker network, LibreChat can use that endpoint directly.

## Available MCP tools

Based on `server.py`, the MCP server provides these tools:

### `get_pokemon(name_or_id)`
Returns core Pokémon data such as id, types, abilities, stats, and image.

### `get_pokemon_species(name_or_id)`
Returns species-level information such as genus, habitat, color, shape, legendary/mythical flags, and Pokédex flavor text.

### `search_pokemon(query, limit=10)`
Searches Pokémon by partial name and returns richer results including id and image URL.

### `list_pokemon_by_type(type_name, limit=10)`
Lists Pokémon that belong to a given type.

### `get_type_matchup(type_name)`
Returns strengths, weaknesses, resistances, and immunities for a Pokémon type.

### `get_evolution_chain(name_or_id)`
Returns the evolution chain for a Pokémon.

### `compare_pokemon(pokemon_1, pokemon_2)`
Compares two Pokémon by types, abilities, and base stats.

## Example prompts

Here are some prompts you can try in LibreChat.

### Basic Pokémon lookup

- `Tell me about Pikachu.`
- `Get the details for Charizard.`
- `Show me the stats, abilities, and types of Bulbasaur.`

### Species information

- `Is Mew mythical or legendary?`
- `What habitat and color does Eevee have?`
- `Give me the Pokédex description for Gengar.`

### Search

- `Search for Pokémon whose name starts with char.`
- `Find Pokémon matching squirt.`
- `Show me 5 Pokémon related to the query pika.`

### Types and matchups

- `List 10 electric-type Pokémon.`
- `What is the fire type strong against?`
- `What are the weaknesses and resistances of steel type?`
- `Which types are immune to ghost attacks?`

### Evolution chains

- `How does Dratini evolve?`
- `Show me the full evolution chain of Charmander.`
- `What are all the evolutions of Eevee?`

### Comparison prompts

- `Compare Pikachu and Raichu.`
- `Which one is faster: Gengar or Alakazam?`
- `Compare Dragonite and Salamence by base stats.`
- `Which Pokémon is bulkier between Snorlax and Lapras?`

## Notes

- The Pokémon data is fetched live from **https://pokeapi.co/** through the MCP server.
- LibreChat is configured to use the MCP server from inside Docker Compose.
- If the stack starts correctly but the chat cannot use Pokémon tools, check the service logs with `make logs` or `make logs-mcp`.

## Troubleshooting

### The stack does not start

Try:

```bash
make build
make up-d
make ps
make logs
```

### LibreChat opens but tools are not working

Check:

- that `ollama` is running
- that `pokemon-mcp` is running
- that LibreChat is using the provided `librechat.yaml`

Then inspect logs:

```bash
make logs-mcp
make logs-ollama
```

### Environment file is missing

Run:

```bash
make init
```

## Tech stack

- **LibreChat**
- **Ollama**
- **FastMCP**
- **Python 3.11+**
- **Docker Compose**
- **PokeAPI**

---