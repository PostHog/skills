"""Create signed commits on a branch through GraphQL, in size-capped batches.

The org ruleset requires signed commits with no bypass actors, so commits are
created server-side via createCommitOnBranch (GitHub signs them). One mutation
carrying a whole catch-up diff (thousands of files, tens of MB) times out with
a 504, so the staged diff is split into batches; each mutation's returned oid
becomes the next one's expectedHeadOid. On failure a batch halves and retries.

Inputs (env): GH_TOKEN, BRANCH, COMMIT_MESSAGE, GITHUB_REPOSITORY.
Reads the staged diff of the current checkout (git diff --cached).
"""

import base64
import json
import os
import subprocess
import sys
import time

MAX_FILES = 200
MAX_BYTES = 4 * 1024 * 1024  # raw bytes per batch; ~5.3 MB as base64
MAX_HALVINGS = 3

REPO = os.environ["GITHUB_REPOSITORY"]
BRANCH = os.environ["BRANCH"]
MESSAGE = os.environ["COMMIT_MESSAGE"]

MUTATION = """
mutation($input: CreateCommitOnBranchInput!) {
  createCommitOnBranch(input: $input) { commit { oid } }
}
"""


def staged_changes():
    """(additions, deletions) from the staged diff. Renames become add+delete."""
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-status", "-z", "--no-renames"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    fields = out.split("\0")
    additions, deletions = [], []
    i = 0
    while i < len(fields) - 1:
        status, path = fields[i], fields[i + 1]
        if status.startswith("D"):
            deletions.append(path)
        else:
            additions.append(path)
        i += 2
    return additions, deletions


def head_oid():
    return subprocess.run(
        ["git", "rev-parse", "HEAD"], check=True, capture_output=True, text=True
    ).stdout.strip()


def batches(additions, deletions):
    """Yield (adds, deletes) batches under the file and byte caps."""
    pending_adds = list(additions)
    pending_dels = list(deletions)
    while pending_adds or pending_dels:
        adds, size = [], 0
        while pending_adds and len(adds) < MAX_FILES:
            path = pending_adds[0]
            file_size = os.path.getsize(path)
            if adds and size + file_size > MAX_BYTES:
                break
            adds.append(pending_adds.pop(0))
            size += file_size
        dels = []
        if not pending_adds:  # deletions are cheap; send them with the last batch
            dels, pending_dels = pending_dels, []
        yield adds, dels


def commit_batch(adds, dels, expected_head):
    file_changes = {
        "additions": [
            {
                "path": p,
                "contents": base64.b64encode(open(p, "rb").read()).decode(),
            }
            for p in adds
        ],
        "deletions": [{"path": p} for p in dels],
    }
    payload = {
        "query": MUTATION,
        "variables": {
            "input": {
                "branch": {
                    "repositoryNameWithOwner": REPO,
                    "branchName": BRANCH,
                },
                "message": {"headline": MESSAGE},
                "expectedHeadOid": expected_head,
                "fileChanges": file_changes,
            }
        },
    }
    result = subprocess.run(
        ["gh", "api", "graphql", "--input", "-"],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip()[:500])
    body = json.loads(result.stdout)
    if body.get("errors"):
        raise RuntimeError(json.dumps(body["errors"])[:500])
    return body["data"]["createCommitOnBranch"]["commit"]["oid"]


def commit_with_retry(adds, dels, expected_head, halvings=0):
    try:
        return commit_batch(adds, dels, expected_head)
    except RuntimeError as e:
        if halvings >= MAX_HALVINGS or (len(adds) <= 1 and not dels):
            raise
        print(f"  batch of {len(adds)}+{len(dels)} failed ({e}); halving")
        time.sleep(2 * (halvings + 1))
        mid_a, mid_d = len(adds) // 2, len(dels) // 2
        head = commit_with_retry(adds[:mid_a], dels[:mid_d], expected_head, halvings + 1)
        return commit_with_retry(adds[mid_a:], dels[mid_d:], head, halvings + 1)


def main():
    additions, deletions = staged_changes()
    if not additions and not deletions:
        print("Nothing staged; nothing to commit.")
        return
    print(f"{len(additions)} additions, {len(deletions)} deletions")
    head = head_oid()
    n = 0
    for adds, dels in batches(additions, deletions):
        n += 1
        head = commit_with_retry(adds, dels, head)
        print(f"  commit {n}: {len(adds)} additions, {len(dels)} deletions -> {head[:10]}")
    print(f"Done: {n} signed commits on {BRANCH}")


if __name__ == "__main__":
    sys.exit(main())
