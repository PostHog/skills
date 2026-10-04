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
    and(less($start_timestamp, toDateTime('2026-10-04 13:51:51.524778')), greater($start_timestamp, toDateTime('2026-10-03 13:51:46.525191')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
