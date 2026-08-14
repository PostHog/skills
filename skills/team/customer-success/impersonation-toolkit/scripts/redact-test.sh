#!/usr/bin/env bash
#
# Regression tests for redact.sh. Run manually: `bash scripts/redact-test.sh`.
# When a new token shape lands in the wild and gets a new named rule in
# redact.sh, add a case here so the pattern is regression-tested.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REDACT="$SCRIPT_DIR/redact.sh"

pass=0
fail=0

run() {
  local name="$1" input="$2" expected="$3" got
  got="$(printf '%s' "$input" | "$REDACT")"
  if [[ "$got" == "$expected" ]]; then
    pass=$((pass+1))
    printf '  PASS  %s\n' "$name"
  else
    fail=$((fail+1))
    printf '  FAIL  %s\n' "$name"
    printf '        input:    %s\n' "$input"
    printf '        expected: %s\n' "$expected"
    printf '        got:      %s\n' "$got"
  fi
}

# --- named prefix rules ---
run "Bearer hex tail"                 'Authorization: Bearer abcdef1234567890abcdef1234567890'  'Authorization: Bearer <REDACTED-TOKEN>'
run "Bearer base64url tail"           'Bearer aGVsbG8td29ybGRfdGVzdC1zdHJpbmc'                  'Bearer <REDACTED-TOKEN>'
run "phc_ prefix"                     'phc_ABCDEFGH1234'                                        'phc_<REDACTED-TOKEN>'
run "phx_ prefix"                     'phx_XYZ9876543'                                          'phx_<REDACTED-TOKEN>'
run "phs_ prefix"                     'invalid phs_secret_key_here_abc'                         'invalid phs_<REDACTED-TOKEN>'
run "sTOK_ prefix"                    'sTOK_abcdef123'                                          'sTOK_<REDACTED-TOKEN>'

# --- JWT ---
run "JWT base64url"                   'token: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.SflKxwRJSMeKKF2QT4fw'                   'token: <REDACTED-JWT>'
run "JWT with + and / in payload"     'token: eyJhbGciOi.eyJz+wI/12MifQ.SflKxwRJSMeKKF2QT4fw'                                  'token: <REDACTED-JWT>'

# --- cookies ---
run "cookie header uppercase"         'Set-Cookie: sessionid=xyz_val; Path=/'                   'Set-Cookie: <REDACTED-COOKIE>'
run "cookie header lowercase"         'cookie: sessionid=xyz_val'                               'cookie: <REDACTED-COOKIE>'

# --- framed secrets (the replacement for the old catch-all) ---
run "framed authorization + token= "  'authorization: eyJhbGciOi.eyJzdWIi.SflKxwRJ and token=abc123def456ghi789' 'authorization: <REDACTED-JWT> and token=<REDACTED-TOKEN>'
run "framed access_token JSON"        '{"access_token":"abcdef1234567890abcdef1234567890"}'     '{"access_token":"<REDACTED-TOKEN>"}'
run "framed code= param"              'callback?code=4/0AVMBsJgH-bYd8U9K3fRvHZ2wQ'               'callback?code=<REDACTED-TOKEN>'
run "framed secret with space sep"    'secret abcdef1234567890'                                 'secret <REDACTED-TOKEN>'

# --- multiple tokens on one line ---
run "multiple tokens same line"       'Bearer abcdef1234567890abcdef1234567890 and phs_secret_key_xyz123' 'Bearer <REDACTED-TOKEN> and phs_<REDACTED-TOKEN>'

# --- must NOT be redacted (the whole reason we dropped the catch-all) ---
run "long flag key stays"             'flag: checkout-conversion-experiment-v2 rejected'        'flag: checkout-conversion-experiment-v2 rejected'
run "PascalCase exception stays"      'Raised ProjectMembershipValidationFailed at boundary'    'Raised ProjectMembershipValidationFailed at boundary'
run "long slug stays"                 'account: really-long-customer-account-slug'              'account: really-long-customer-account-slug'
run "URL path stays"                  'GET /api/experiments?limit=10'                           'GET /api/experiments?limit=10'
run "plain English stays"             'the impersonation session lapsed and switch-project returned 403' 'the impersonation session lapsed and switch-project returned 403'
run "regular filename stays"          'writing to refusals-log-file.json'                       'writing to refusals-log-file.json'
run "empty input"                     ''                                                        ''

# --- compound-key false positives (the keyword must be a word start) ---
run "compound error_code stays"       'error_code: resource_not_found_here'                     'error_code: resource_not_found_here'
run "compound reason_code stays"      'reason_code=INVALID_TOKEN_HERE'                          'reason_code=INVALID_TOKEN_HERE'
run "compound status_code stays"      'status_code=tool_not_found_ever'                         'status_code=tool_not_found_ever'
run "json code with diagnostic stays" '{"error":{"code":"resource_not_found"}}'                 '{"error":{"code":"resource_not_found"}}'
run "code= diagnostic string stays"   'code: PROJECT_NOT_FOUND'                                 'code: PROJECT_NOT_FOUND'

# --- but a compound key with a digit-bearing token value STILL redacts if the keyword itself is real ---
run "token= real value still redacts" 'token=abc123def456ghi789'                                'token=<REDACTED-TOKEN>'

echo
echo "  ${pass} passed, ${fail} failed"

if (( fail > 0 )); then
  exit 1
fi
