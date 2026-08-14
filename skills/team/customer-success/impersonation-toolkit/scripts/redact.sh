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
#
# Each rule names the shape it is redacting. There is deliberately no
# "long-string-in-alphabet" catch-all — that pattern ate legitimate identifiers
# (long flag keys, PascalCase exception classes, kebab-case slugs) and the
# debug log's whole value is preserving those exact strings so a human can
# grep them. When a new token shape shows up in the wild, add a named rule.
exec perl -pe '
  # JWT: three base64-or-base64url segments separated by dots, header starts
  # with eyJ. Standard base64 (`+`, `/`) is included so we handle non-strict
  # encoders as well as RFC 7515 base64url.
  s{\beyJ[A-Za-z0-9+/=_-]{5,}\.[A-Za-z0-9+/=_-]{5,}\.[A-Za-z0-9+/=_-]{5,}\b}{<REDACTED-JWT>}g;

  # Bearer tokens — hex, base64, or base64url tail.
  s{\bBearer\s+[A-Za-z0-9+/=_.\-]{8,}}{Bearer <REDACTED-TOKEN>}gi;

  # PostHog token prefixes. No length floor — the prefix alone is enough
  # signal that whatever follows is secret material.
  s{\b(phc_|phx_|phs_|sTOK_)[A-Za-z0-9_\-]+}{$1<REDACTED-TOKEN>}g;

  # Cookie / Set-Cookie header values.
  s{(?i)(cookie:\s*)([^\r\n]+)}{$1<REDACTED-COOKIE>}g;
  s{(?i)(set-cookie:\s*)([^\r\n]+)}{$1<REDACTED-COOKIE>}g;

  # Framed secret rule — a keyword like "token", "code", "authorization"
  # followed by a token-shaped value. Anchored on the keyword so it names
  # what it is protecting; leaves free-standing identifiers alone.
  # Handles JSON (`"access_token":"..."`), query-string (`code=...`), and
  # plain (`token abc123`) framings.
  s{
    ((?i:access_token|refresh_token|authorization|api_key|secret|token|code))  # keyword
    (["\x27]?)                                                                  # optional closing quote after keyword (JSON)
    (\s*[:=]\s*|\s+)                                                            # separator (colon, equals, or whitespace)
    (["\x27]?)                                                                  # optional opening quote before value
    ([A-Za-z0-9+/=_.\-]{8,})                                                    # token-shaped value
  }{$1$2$3$4<REDACTED-TOKEN>}gx;
'
