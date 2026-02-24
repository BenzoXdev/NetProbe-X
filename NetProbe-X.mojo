"""
NetProbe-X Enterprise — Professional TCP port scanner in Mojo.
Usage: mojo run NetProbe-X.mojo <target> [options]
"""
from sys import argv
from socket import socket, AF_INET, SOCK_STREAM, gethostbyname, gaierror
from time import time
from threading import Thread, Lock
from queue import Queue, Empty
from json import dumps

alias Port = Int
let SENTINEL: Port = -1  # Task completion marker for workers

struct EnterpriseConfig:
    var target: String
    var start_port: Int
    var end_port: Int
    var timeout: Float64
    var threads: Int
    var verbose: Bool
    var output_file: String

var task_queue = Queue[Port]()
var open_ports: List[Port] = []
var ports_lock = Lock()

fn color(code: Int):
    print("\033[" + str(code) + "m", end="")

fn reset():
    print("\033[0m", end="")

fn print_banner():
    color(31)
    print("""\
                                        )             (                                  )  
                                    ( /(           ) )\ )              )             ( /(  
                                    )\())   (   ( /((()/( (         ( /(    (        )\()) 
                                    ((_)\   ))\  )\())/(_)))(    (   )\())  ))\  ___ ((_)\  
                                    _((_) /((_)(_))/(_)) (()\   )\ ((_)\  /((_)|___|__((_) 
                                    | \| |(_))  | |_ | _ \ ((_) ((_)| |(_)(_))       \ \/ / 
                                    | .` |/ -_) |  _||  _/| '_|/ _ \| '_ \/ -_)       >  <  
                                    |_|\_|\___|  \__||_|  |_|  \___/|_.__/\___|      /_/\_\ 
                                                                                            
""")
    print("   NetProbe-X Enterprise — Port Scanner")
    print("   Author: benzoXdev\n")
    reset()

fn print_usage():
    print("Usage: mojo run NetProbe-X.mojo <target> [options]")
    print("  target             IP address or hostname to scan")
    print("  -p, --ports N-M    Port range (default: 1-65535)")
    print("  -t, --timeout S    Timeout in seconds (default: 1.0)")
    print("  -j, --threads N    Number of threads (default: 200)")
    print("  -o, --output FILE  JSON output file (default: enterprise_scan.json)")
    print("  -q, --quiet        Do not print open ports in real time")
    print("  -h, --help         Show this help")

fn resolve_target(host: String) -> String:
    """Resolve hostname to IP or return the address as-is."""
    try:
        return gethostbyname(host)
    except gaierror:
        return ""

fn scan_worker(ip: String, timeout: Float64, verbose: Bool):
    while True:
        try:
            var port = task_queue.get(block=True, timeout=0.25)
            if port == SENTINEL:
                return
        except Empty:
            continue

        var s = socket(AF_INET, SOCK_STREAM)
        s.settimeout(timeout)

        try:
            s.connect((ip, port))
            s.close()
            ports_lock.acquire()
            open_ports.append(port)
            ports_lock.release()
            if verbose:
                color(32)
                print("[OPEN]", port)
                reset()
        except:
            pass

fn export_results(ip: String, out_path: String, duration_sec: Float64):
    var sorted_ports: List[Port] = []
    for p in open_ports:
        sorted_ports.append(p)
    sorted_ports.sort()

    var data = {
        "target": ip,
        "open_ports": sorted_ports,
        "duration_seconds": duration_sec,
        "author": "benzoXdev",
        "edition": "Enterprise"
    }
    var json_str = dumps(data, indent=2)
    var f = open(out_path, "w")
    f.write(json_str)
    f.close()

fn parse_ports(s: String) -> (Int, Int):
    """Parse port range 'N-M' or single port 'N'. Returns (start, end)."""
    if "-" in s:
        var parts = s.split("-")
        if len(parts) != 2:
            return (-1, -1)
        var a = int(parts[0].strip())
        var b = int(parts[1].strip())
        if a < 1 or b > 65535 or a > b:
            return (-1, -1)
        return (a, b)
    else:
        var n = int(s.strip())
        if n < 1 or n > 65535:
            return (-1, -1)
        return (n, n)

fn main():
    if len(argv) < 2:
        print_usage()
        return

    var i = 1
    var target = ""
    var start_port: Int = 1
    var end_port: Int = 65535
    var timeout: Float64 = 1.0
    var threads: Int = 200
    var output_file = "enterprise_scan.json"
    var verbose = True

    while i < len(argv):
        var arg = argv[i]
        if arg == "-h" or arg == "--help":
            print_usage()
            return
        if arg == "-q" or arg == "--quiet":
            verbose = False
            i += 1
            continue
        if arg == "-p" or arg == "--ports":
            if i + 1 >= len(argv):
                color(31)
                print("Error: -p/--ports requires a range (e.g. 1-1000)")
                reset()
                return
            var lo, hi = parse_ports(argv[i + 1])
            if lo < 0:
                color(31)
                print("Error: invalid port range (use 1 <= N <= M <= 65535)")
                reset()
                return
            start_port = lo
            end_port = hi
            i += 2
            continue
        if arg == "-t" or arg == "--timeout":
            if i + 1 >= len(argv):
                color(31)
                print("Error: -t/--timeout requires a value in seconds")
                reset()
                return
            timeout = float(argv[i + 1])
            if timeout <= 0 or timeout > 300:
                timeout = 1.0
            i += 2
            continue
        if arg == "-j" or arg == "--threads":
            if i + 1 >= len(argv):
                color(31)
                print("Error: -j/--threads requires a number")
                reset()
                return
            threads = int(argv[i + 1])
            if threads < 1:
                threads = 1
            if threads > 2000:
                threads = 2000
            i += 2
            continue
        if arg == "-o" or arg == "--output":
            if i + 1 >= len(argv):
                color(31)
                print("Error: -o/--output requires a file path")
                reset()
                return
            output_file = argv[i + 1]
            i += 2
            continue
        if not arg.startswith("-"):
            target = arg
            i += 1
            break
        i += 1

    if target == "":
        color(31)
        print("Error: no target specified.")
        print_usage()
        reset()
        return

    var resolved = resolve_target(target)
    if resolved == "":
        color(31)
        print("Error: could not resolve '" + target + "' (check IP or hostname)")
        reset()
        return

    var config = EnterpriseConfig(
        target=resolved,
        start_port=start_port,
        end_port=end_port,
        timeout=timeout,
        threads=threads,
        verbose=verbose,
        output_file=output_file
    )

    print_banner()

    if resolved != target:
        print("Target:", target, "->", resolved)
    else:
        print("Target:", config.target)
    print("Ports:", config.start_port, "-", config.end_port)
    print("Threads:", config.threads)
    print("Timeout:", config.timeout, "s")
    print("")

    var total_ports = config.end_port - config.start_port + 1
    for port in range(config.start_port, config.end_port + 1):
        task_queue.put(port)

    for _ in range(config.threads):
        task_queue.put(SENTINEL)

    var start_time = time()
    var workers: List[Thread] = []

    for _ in range(config.threads):
        var t = Thread(target=scan_worker, args=(config.target, config.timeout, config.verbose))
        t.start()
        workers.append(t)

    for w in workers:
        w.join()

    var duration = time() - start_time

    var sorted_ports: List[Port] = []
    for p in open_ports:
        sorted_ports.append(p)
    sorted_ports.sort()

    color(33)
    print("\n--- Scan completed ---")
    reset()

    print("Open ports:", len(sorted_ports), "/", total_ports)
    if len(sorted_ports) > 0:
        print("List:", sorted_ports)
    print("Duration:", duration, "seconds")

    export_results(config.target, config.output_file, duration)
    color(32)
    print("Results exported to:", config.output_file)
    reset()

main()
