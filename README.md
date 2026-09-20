# AI Orchestrator prototype

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

This repository contains shell and Python experiments for coordinating Claude sessions through tmux, decomposing tasks, assigning workers, and discovering MCP tools.

It is a prototype. It does not provide a security sandbox, encrypted inter-agent messaging, compliance controls, or production isolation.

## Implemented components

- tmux session creation and lifecycle scripts;
- recursive task decomposition and agent matching experiments;
- JSON messages over local named pipes;
- MCP marketplace scanning and template generation;
- local telemetry, governance, and performance experiments;
- phase-specific scripts and historical validation notes.

## Security boundary

Tmux separates terminal processes. It does not isolate files, credentials, environment variables, the network, or the operating system.

The current message handlers mark payloads as unencrypted and use placeholder signatures or hashes. Named-pipe permissions limit ordinary local access, but they do not provide cryptographic confidentiality or authenticity.

Do not use this repository for secrets, regulated data, untrusted code, or production authorization decisions.

## Requirements

- Bash
- tmux 3.0 or newer
- jq
- Python 3

Some experiments also use SQLite, NumPy, pandas, or scikit-learn.

## Run locally

```sh
git clone https://github.com/pkmdev-sec/revolutionary-ai-orchestrator.git
cd revolutionary-ai-orchestrator
chmod +x src/*.sh

./src/master-orchestrator.sh orchestrate "Analyze this task"
```

Review a script before running it. Several commands create tmux sessions, local state, named pipes, or generated configuration.

## Repository layout

| Path | Contents |
|---|---|
| `src/` | orchestration, session, messaging, and integration scripts |
| `engines/` | experimental analysis and coordination engines |
| `security/` | cryptography and security prototypes |
| `claude-integration/` | Claude command and hook examples |
| `docs/` | phase notes and design material |
| `tests/` | shell-based phase and integration checks |

## Evidence limits

Historical timing, accuracy, memory, security, and compliance statements under `docs/` and `reports/` are experiment outputs or author assertions. They are not independent benchmarks, audits, certifications, or current production guarantees.

Before claiming a capability, reproduce it on the target host and inspect the implementation that enforces it.

## License

[MIT](LICENSE) © pkmdev-sec
