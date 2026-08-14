#!/usr/bin/env bash
#
# Deterministic redactor for the impersonate-audit debug + refusal logs.
# Reads stdin, writes redacted output to stdout. Never modifies files itself —
# the caller pipes into it and writes the result wherever they need to.
#
# Redaction is done outside the LLM so it can't be prompt-injected into
# skipping a rule. Patterns are conservative — a false positive (over-redact)
# is safer than a false negative (leak).

set -euo pipefail

# perl is the portable choice for PCRE-like alternation and lookbehind.
# It ships on macOS by default and every Linux distro we care about.
exec perl -pe '
  # JWT: three base64url segments separated by dots, header starts with eyJ.
  s{\beyJ[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}\b}{<REDACTED-JWT>}g;

  # Bearer tokens — hex, base64, or base64url tail.
  s{\bBearer\s+[A-Za-z0-9+/=_.\-]{8,}}{Bearer <REDACTED-TOKEN>}gi;

  # PostHog token prefixes we know about. No length floor — the prefix alone
  # is enough signal that whatever follows is secret material.
  s{\b(phc_|phx_|phs_|sTOK_)[A-Za-z0-9_\-]+}{$1<REDACTED-TOKEN>}g;

  # Cookie / Set-Cookie header values.
  s{(?i)(cookie:\s*)([^\r\n]+)}{$1<REDACTED-COOKIE>}g;
  s{(?i)(set-cookie:\s*)([^\r\n]+)}{$1<REDACTED-COOKIE>}g;

  # Catch-all for token-shaped blobs (24+ chars from the base64url + padding
  # alphabet). Lower than 32 so short OAuth codes are still caught. Anchored
  # on word boundaries so it does not eat ordinary long identifiers embedded
  # in words. Applies after the specific rules above so those wins.
  s{\b[A-Za-z0-9+/=_-]{24,}\b}{<REDACTED-TOKEN>}g;
'
