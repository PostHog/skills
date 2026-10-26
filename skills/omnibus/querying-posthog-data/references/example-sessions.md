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
    and(less($start_timestamp, toDateTime('2026-10-26 13:26:01.079173')), greater($start_timestamp, toDateTime('2026-10-25 13:25:56.079563')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
