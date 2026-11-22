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
    and(less($start_timestamp, toDateTime('2026-11-22 12:02:02.450242')), greater($start_timestamp, toDateTime('2026-11-21 12:01:57.450632')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
