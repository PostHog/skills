# Sessions (listing sessions with duration, pageviews, and bounce rate)

```sql
SELECT
    session_id,
    $start_timestamp,
    $end_timestamp,
    $session_duration,
    $pageview_count,
    $is_bounce,
    $entry_current_url,
    $end_current_url
FROM
    sessions
WHERE
    and(less($start_timestamp, toDateTime('2026-11-18 11:54:22.509884')), greater($start_timestamp, toDateTime('2026-11-17 11:54:17.510237')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
