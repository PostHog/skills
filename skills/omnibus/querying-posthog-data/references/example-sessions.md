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
    and(less($start_timestamp, toDateTime('2026-10-22 12:09:31.845613')), greater($start_timestamp, toDateTime('2026-10-21 12:09:26.845989')))
ORDER BY
    $start_timestamp DESC
LIMIT 50000
```
