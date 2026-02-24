# NetProbe-X Enterprise

**High-performance TCP port scanner** written in [Mojo](https://docs.modular.com/mojo/). Fast, threaded, configurable, with JSON export and hostname resolution.

---

## Features

| Feature | Description |
|--------|-------------|
| **Multi-threaded** | Configurable worker threads (default 200) for fast scans |
| **Hostname resolution** | Accepts IP addresses or hostnames (DNS resolution) |
| **Port range** | Scan a custom range (e.g. `1-1000`) or full 1–65535 |
| **Configurable timeout** | Per-connection timeout in seconds |
| **JSON export** | Results saved to a JSON file with target, open ports, duration |
| **Thread-safe** | Lock-protected shared state; sentinel-based worker shutdown (no deadlocks) |
| **Sorted results** | Open ports are sorted numerically in output and export |
| **CLI options** | Full command-line interface with short and long flags |

---

## Requirements

- **Mojo** (Modular Mojo SDK)  
  Install from [Modular](https://docs.modular.com/mojo/manual/get-started) and ensure `mojo` is on your `PATH`.

- **Python interop** (used by Mojo for `socket`, `threading`, `queue`, `json`) — no extra Python install required if Mojo is set up correctly.

---

## Installation

1. **Install Mojo** (see [Get started with Mojo](https://docs.modular.com/mojo/manual/get-started)).

2. **Clone or download** the project:
   ```bash
   cd NetProbe-X
   ```

3. **Run** the scanner (no build step required):
   ```bash
   mojo run NetProbe-X.mojo <target> [options]
   ```

---

## Usage

### Synopsis

```text
mojo run NetProbe-X.mojo <target> [options]
```

### Arguments and options

| Option | Short | Description | Default |
|--------|--------|-------------|--------|
| `--help` | `-h` | Show usage and exit | — |
| `--ports N-M` | `-p` | Port range to scan (e.g. `1-1000`, `80`, `22-443`) | `1-65535` |
| `--timeout S` | `-t` | Connection timeout in seconds (float) | `1.0` |
| `--threads N` | `-j` | Number of worker threads (1–2000) | `200` |
| `--output FILE` | `-o` | JSON output file path | `enterprise_scan.json` |
| `--quiet` | `-q` | Do not print open ports in real time | off |

- **target**: IP address or hostname to scan (required).

---

## Examples

**Basic scan (all ports, default settings):**
```bash
mojo run NetProbe-X.mojo 192.168.1.1
```

**Scan common web ports with 100 threads:**
```bash
mojo run NetProbe-X.mojo example.com -p 80-443 -j 100
```

**Custom output file and timeout:**
```bash
mojo run NetProbe-X.mojo 10.0.0.1 -p 22-8080 -o scan.json -t 2
```

**Quiet mode (only summary at the end):**
```bash
mojo run NetProbe-X.mojo 127.0.0.1 -q -o results.json
```

**Show help:**
```bash
mojo run NetProbe-X.mojo --help
```

---

## Output

### Console

- Banner and scan parameters (target, port range, threads, timeout).
- Real-time `[OPEN] <port>` lines (unless `-q`).
- Final summary: open port count, full list (sorted), duration, and export path.

### JSON export

The file specified with `-o` (default: `enterprise_scan.json`) contains:

```json
{
  "target": "192.168.1.1",
  "open_ports": [22, 80, 443],
  "duration_seconds": 12.34,
  "author": "benzoXdev",
  "edition": "Enterprise"
}
```

- **target**: Resolved IP (or same as input if it was already an IP).
- **open_ports**: Sorted list of open port numbers.
- **duration_seconds**: Total scan time in seconds.

---

## Implementation notes

- **Threading**: Worker threads consume ports from a shared queue; completion is signaled with sentinel values to avoid deadlocks.
- **Concurrency**: Access to the list of open ports is protected by a lock.
- **Resolution**: Target is resolved once at startup via `gethostbyname`; failures produce a clear error and exit.

---

## License and author

- **Author**: benzoXdev  
- **Project**: NetProbe-X Enterprise  

Use responsibly and only on networks and hosts you are authorized to scan.

---

## Contributing

Improvements and fixes are welcome (e.g. via pull requests or issues). Keep the code in English and the README aligned with the current CLI and behavior.
