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
    and(less($start_timestamp, toDateTime('2026-06-29 13:26:05.796811')), greater($start_timestamp, toDateTime('2026-06-28 13:26:00.797893')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
