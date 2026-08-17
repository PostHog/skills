#!/usr/bin/env python3
"""Run PostHog HogQL queries over the HTTP API. Run this file, never read it to copy its shapes.

Why it exists: every query this skill fires carries `$group_0`, `$session_id` or a dollar
figure, and bash eats those inside an inline string, so the payload has to be built in
Python and handed to curl as a file. Python's own urllib hits CERTIFICATE_VERIFY_FAILED on
this machine, so curl does the request and Python only builds and parses JSON. Getting
either half wrong returns a plausible wrong number rather than an error, which is the whole
reason this is a script instead of a paragraph.

Four targets, because the endpoint, the key and the payload shape all change together:

  us     project 2 catalog          us.posthog.com/api/projects/2/query/  POSTHOG_PERSONAL_API_KEY
  eu     EU project 1 catalog       eu.posthog.com/api/projects/1/query/  POSTHOG_PERSONAL_API_KEY_EU
  ch-us  US direct ClickHouse       us endpoint + connectionId            POSTHOG_PERSONAL_API_KEY
  ch-eu  EU direct ClickHouse       eu endpoint + connectionId            POSTHOG_PERSONAL_API_KEY_EU

The two ch- targets read a customer's OWN raw product events, so every query against them
must filter team_id explicitly or it silently returns PostHog-wide numbers.

Usage:
  phq.py us "SELECT count() FROM events WHERE $group_0 = '<org>' LIMIT 1"
  phq.py ch-eu --sql-file /tmp/q.sql
  phq.py --batch /tmp/<agent>-queries.jsonl  # one {"name","target","sql"} object per line
                                             # NAMESPACE the filename per agent. Several gatherers
                                             # run at once and a shared path gets overwritten mid-run.
  phq.py us "..." --raw                      # full JSON instead of the TSV table

Batch mode is the point: these reads do not depend on each other, so one invocation fires
them concurrently (default width 6, --concurrency to change), which is what keeps a run's depth down. Exit code is 0 when every
query returned, 1 when any failed.

Needs: python3 (stdlib only) and curl. No pip packages.
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor

# Endpoint, env var holding the key, and whether the target needs a ClickHouse connection id.
TARGETS = {
    "us":    ("https://us.posthog.com/api/projects/2/query/", "POSTHOG_PERSONAL_API_KEY",    None),
    "eu":    ("https://eu.posthog.com/api/projects/1/query/", "POSTHOG_PERSONAL_API_KEY_EU", None),
    "ch-us": ("https://us.posthog.com/api/projects/2/query/", "POSTHOG_PERSONAL_API_KEY",    "us"),
    "ch-eu": ("https://eu.posthog.com/api/projects/1/query/", "POSTHOG_PERSONAL_API_KEY_EU", "eu"),
}

# The Production ClickHouse source in each region's internal project. Written down because
# they have been stable, but they are configuration and not law: on a 400 naming connectionId,
# re-discover with `call external-data-sources-connections-list {}` (US) or
# GET /api/projects/1/external_data_sources/?limit=100 (EU), taking the row with
# source_type ClickHouse and prefix Production, then pass --connection.
CONNECTIONS = {
    "us": "019fa95f-caa3-0000-4452-6dc502c7eb96",
    "eu": "019fd687-7e09-0000-bbf2-cd4fc538c514",
}

# A wide query over the usage report can take a minute; anything past this is the server's
# execution ceiling rather than a slow network, and the fix is a narrower window, not a longer wait.
TIMEOUT = 180

# The EU HTTP API throttles at a much lower width than ClickHouse: a measured 12-wide batch
# returned 429 on 3 of 12. Six is under that line and still eight times faster than serial.
CONCURRENCY = 6

# One retry only. A timeout can still land in the server cache, so an identical retry often
# returns instantly; a second one just burns another full wait.
RETRIES = 1


def run_query(name, target, sql, connection=None, timeout=TIMEOUT):
    """Send one query. Returns (name, ok, payload) where payload is the parsed body or an error string."""
    if target not in TARGETS:
        return (name, False, f"unknown target {target!r}, expected one of {', '.join(TARGETS)}")
    url, key_var, region = TARGETS[target]
    key = os.environ.get(key_var, "")
    if not key:
        return (name, False, f"{key_var} is not set in the environment (source ~/.zshenv first)")

    query_obj = {"kind": "HogQLQuery", "query": sql}
    if region:
        # connectionId belongs INSIDE the query object on the HTTP path. As a sibling of
        # `query` the request 400s with "connectionId Extra inputs are not permitted", and
        # snake_case connection_id 400s the same way. Only this placement works.
        query_obj["connectionId"] = connection or CONNECTIONS[region]

    payload = json.dumps({"query": query_obj})
    fd, path = tempfile.mkstemp(suffix=".json", prefix="phq-")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(payload)
        cmd = [
            "curl", "-s", "-S", "--max-time", str(timeout),
            "-X", "POST", url,
            "-H", f"Authorization: Bearer {key}",
            "-H", "Content-Type: application/json",
            "-w", "\n__HTTP_STATUS__%{http_code}",
            "--data", f"@{path}",
        ]
        for attempt in range(RETRIES + 1):
            proc = subprocess.run(cmd, capture_output=True, text=True)
            body, _, status = proc.stdout.rpartition("\n__HTTP_STATUS__")
            if proc.returncode != 0 and not body:
                # curl itself failed (network, timeout). Retry once, then report what it said.
                if attempt < RETRIES:
                    time.sleep(2)
                    continue
                return (name, False, f"curl exit {proc.returncode}: {proc.stderr.strip()[:300]}")
            try:
                parsed = json.loads(body)
            except json.JSONDecodeError:
                return (name, False, f"HTTP {status}: non-JSON response: {body[:300]}")
            if status.startswith("2"):
                return (name, True, parsed)
            detail = str(parsed.get("detail") or parsed.get("message") or json.dumps(parsed))
            transient = status in ("429", "500", "502", "503", "504") or "SIMULTANEOUS" in detail.upper()
            if transient and attempt < RETRIES:
                time.sleep(5)
                continue
            # 1200 chars, not a one-line summary: a HogQL error carries the resolver's
            # "Did you mean" list, which fuzzy-matches the real table names and is often
            # the answer to why a read came back empty. Truncating it hides the fix.
            msg = f"HTTP {status}: {detail[:1200]}"
            if "connectionid" in detail.lower():
                msg += (
                    "\n  hint: the ClickHouse connection id may have changed. Rediscover it with"
                    " `call external-data-sources-connections-list {}` (US) or"
                    " GET /api/projects/1/external_data_sources/?limit=100 (EU), take the row with"
                    " source_type ClickHouse and prefix Production, and pass it as --connection."
                    " Do not report the direct connection as unavailable without trying that."
                )
            return (name, False, msg)
    finally:
        os.unlink(path)


def render(name, ok, payload, raw=False):
    if not ok:
        return f"=== {name} === ERROR {payload}"
    if raw:
        return f"=== {name} ===\n{json.dumps(payload, indent=2, default=str)}"
    cols = payload.get("columns") or []
    rows = payload.get("results", [])
    out = [f"=== {name} === ok rows={len(rows)}"]
    if cols:
        out.append("\t".join(str(c) for c in cols))
    for row in rows:
        cells = row if isinstance(row, (list, tuple)) else [row]
        out.append("\t".join("" if c is None else str(c).replace("\t", " ").replace("\n", " ") for c in cells))
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description="Run PostHog HogQL queries over the HTTP API.")
    ap.add_argument("target", nargs="?", choices=sorted(TARGETS), help="which endpoint and key to use")
    ap.add_argument("sql", nargs="?", help="the query, or use --sql-file")
    ap.add_argument("--sql-file", help="read the query from a file instead of the argument")
    ap.add_argument("--batch", help="JSONL file, one {\"name\",\"target\",\"sql\"} object per line")
    ap.add_argument("--connection", help="override the ClickHouse connectionId for a ch- target")
    ap.add_argument("--concurrency", type=int, default=CONCURRENCY, help=f"parallel width in batch mode (default {CONCURRENCY})")
    ap.add_argument("--timeout", type=int, default=TIMEOUT, help=f"seconds per query (default {TIMEOUT})")
    ap.add_argument("--raw", action="store_true", help="print full JSON instead of the TSV table")
    args = ap.parse_args()

    jobs = []
    if args.batch:
        with open(args.batch) as fh:
            for i, line in enumerate(fh, 1):
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                try:
                    spec = json.loads(line)
                except json.JSONDecodeError as exc:
                    print(f"=== line {i} === ERROR unparseable JSONL: {exc}", file=sys.stderr)
                    return 1
                jobs.append((spec.get("name", f"query-{i}"), spec["target"], spec["sql"], spec.get("connection")))
    else:
        if not args.target:
            ap.error("give a target and a query, or --batch")
        sql = args.sql
        if args.sql_file:
            with open(args.sql_file) as fh:
                sql = fh.read()
        if not sql:
            ap.error("give a query as the second argument or via --sql-file")
        jobs.append(("query", args.target, sql, args.connection))

    width = max(1, min(args.concurrency, len(jobs)))
    with ThreadPoolExecutor(max_workers=width) as pool:
        results = list(pool.map(
            lambda j: run_query(j[0], j[1], j[2], connection=j[3] or args.connection, timeout=args.timeout),
            jobs,
        ))

    failed = 0
    for name, ok, payload in results:
        if not ok:
            failed += 1
        print(render(name, ok, payload, raw=args.raw))
        print()
    if failed:
        print(f"{failed} of {len(results)} queries failed", file=sys.stderr)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
