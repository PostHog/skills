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
    and(less($start_timestamp, toDateTime('2026-11-25 12:03:45.332410')), greater($start_timestamp, toDateTime('2026-11-24 12:03:40.332709')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
