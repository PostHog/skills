> AI agents: this is one page from PostHog's docs. Full index of Markdown docs for LLMs: https://posthog.com/llms.txt

# PostHog Go SDK

Canonical URL: https://posthog.com/docs/libraries/go/reference

> **Cloud region:** This page uses US Cloud hosts. For an EU Cloud project, use `https://eu.i.posthog.com` instead of `https://us.i.posthog.com` (ingestion host).

## On this page

- [Getting started](#getting-started)
- [Setup](#setup)
- [Capture](#capture)
- [Identify](#identify)
- [Alias](#alias)
- [Capture exception](#capture-exception)
- [Emails](#emails)
- [Flush](#flush)
- [Get feature flag](#get-feature-flag)
- [Get feature flag payload](#get-feature-flag-payload)
- [Get feature flag result](#get-feature-flag-result)
- [Get feature flags](#get-feature-flags)
- [Evaluate flags](#evaluate-flags)
- [Group identify](#group-identify)
- [Is feature enabled](#is-feature-enabled)
- [Reload feature flags](#reload-feature-flags)
- [Shutdown](#shutdown)
- [Before send hook](#before-send-hook)
- [SDK utils](#sdk-utils)
- [FeatureFlagEvaluations](#featureflagevaluations)
- [Types](#types)

## Getting started

The Go SDK runs on your server, on Go 1.21 or later.

To send your first event, create a client with your project token and host from your [project settings](https://app.posthog.com/project/settings), then call `Enqueue` with a `Capture`.

The client queues events and sends them in batches, so call `Close` before your program exits, or the last events are lost.

Install the module (Go 1.21 or later):

```bash
go get github.com/posthog/posthog-go
```

Create a client with your project API key, send an event, and close the client to flush the queue:

```go
package main

import "github.com/posthog/posthog-go"

func main() {
	client, _ := posthog.NewWithConfig("<ph_project_api_key>", posthog.Config{
		Endpoint: "https://us.i.posthog.com",
	})
	defer client.Close() // flushes queued events

	client.Enqueue(posthog.Capture{
		DistinctId: "user_123",
		Event:      "button_clicked",
		Properties: posthog.NewProperties().Set("plan", "pro"),
	})
}
```

## Setup

### `Config`

```go
type Config struct {
	// Endpoint is the PostHog API host used for event ingestion and feature flag requests.
	// If empty, it defaults to DefaultEndpoint.
	Endpoint string

	// SecretKey is the credential used to fetch local feature flag definitions,
	// remote config payloads, and lower-latency flag APIs. It accepts either a Personal
	// API Key (phx_...) or a Project Secret API Key (phs_...). Local evaluation can
	// also use definitions from FlagDefinitionCacheProvider without this key.
	// Without either, feature flag methods fall back to the /flags endpoint unless
	// the method requires local-only behavior. When both SecretKey and PersonalApiKey
	// are set, SecretKey takes precedence.
	// See https://posthog.com/docs/api/overview for how to create these keys.
	SecretKey string

	// PersonalApiKey is a deprecated alias for SecretKey. It is still honored for
	// backwards compatibility but SecretKey is preferred.
	//
	// Deprecated: use SecretKey instead.
	PersonalApiKey string

	// DisableGeoIP controls whether event and feature flag requests include
	// $geoip_disable/geoip_disable. Nil defaults to true because this SDK usually
	// runs server-side; set Ptr(false) to allow GeoIP lookup.
	DisableGeoIP *bool

	// IsServer controls whether events include the $is_server property.
	//
	// Defaults to true: nil is treated as true because posthog-go usually runs
	// server-side, and $is_server lets PostHog identify server-side events.
	//
	// Set Ptr(false) when using posthog-go as a CLI or client so the event is
	// not flagged as server-side and the device OS is attributed normally. When
	// resolved to false, $is_server is omitted from every event entirely.
	//
	//	// CLI/client usage
	//	config := posthog.Config{IsServer: posthog.Ptr(false)}
	IsServer *bool

	// Interval is the flush interval for queued messages. Messages are sent when
	// BatchSize is reached or when this timer fires. If zero, it defaults to
	// DefaultInterval.
	Interval time.Duration

	// DefaultFeatureFlagsPollingInterval is the interval for reloading local feature
	// flag definitions when SecretKey or FlagDefinitionCacheProvider is configured.
	// If zero, it defaults to
	// DefaultFeatureFlagsPollingInterval.
	DefaultFeatureFlagsPollingInterval time.Duration

	// FeatureFlagRequestTimeout is the timeout for feature flag and remote config
	// HTTP requests. If zero, it defaults to DefaultFeatureFlagRequestTimeout.
	// Use time.Duration values such as 3 * time.Second.
	FeatureFlagRequestTimeout time.Duration

	// FeatureFlagRequestMaxRetries is the maximum number of retries after a transient
	// network error on /flags requests. If nil, it defaults to 1. Set to 0 to disable.
	FeatureFlagRequestMaxRetries *int

	// NextFeatureFlagsPollingTick optionally calculates the next local feature flag
	// polling delay. When set, it overrides DefaultFeatureFlagsPollingInterval.
	NextFeatureFlagsPollingTick func() time.Duration

	// FlagDefinitionCacheProvider shares local evaluation flag definitions with other
	// SDK instances through an external cache. Without SecretKey, instances read
	// cached definitions for local evaluation without consulting the provider's
	// fetch decision or publishing. Fetching definitions from PostHog requires
	// SecretKey.
	// See https://posthog.com/docs/feature-flags/local-evaluation/distributed-environments
	// for guidance.
	//
	// EXPERIMENTAL: this API may change in a minor version bump.
	FlagDefinitionCacheProvider FlagDefinitionCacheProvider

	// HistoricalMigration marks captured batches as historical migration traffic.
	// See https://posthog.com/docs/migrate for migration guidance.
	HistoricalMigration bool

	// Transport is the HTTP transport used by the client. Set it to customize
	// low-level request behavior such as connection pooling or proxies. If nil,
	// the client uses a clone of http.DefaultTransport with SDK defaults.
	Transport http.RoundTripper

	// Logger receives informational, warning, and error messages from background
	// operations. If nil, the client logs to os.Stderr with the standard logger.
	Logger Logger

	// DefaultEventProperties are merged into every Capture event before sending.
	// They are useful for common metadata like service name or app version. On key
	// conflicts, values from DefaultEventProperties overwrite event properties,
	// except that an explicit $process_person_profile=false remains false.
	DefaultEventProperties Properties

	// Callback receives success or failure notifications for messages sent to the
	// PostHog batch API.
	Callback Callback

	// BeforeSend is called after SDK enrichment and before messages are serialized.
	// Return the message to send a modified version, or nil to drop it.
	BeforeSend BeforeSendFunc

	// BatchSize is the maximum number of messages sent in one batch API call.
	// Messages are sent when BatchSize is reached or when Interval fires. If zero,
	// it defaults to DefaultBatchSize. The API still enforces a 500KB request limit.
	BatchSize int

	// MaxQueueSize is the maximum number of messages buffered in memory waiting to
	// be batched and sent. If zero, it defaults to DefaultMaxQueueSize. It is
	// clamped up to BatchSize so the queue can always hold at least one full batch.
	//
	// When the queue is full, Enqueue drops the newest message rather than blocking
	// the caller and returns ErrQueueFull (the drop is not reported via
	// Callback.Failure). Bulk or backfill workloads that enqueue faster than the
	// client can upload should check the error returned by Enqueue for ErrQueueFull
	// and throttle or retry (or raise MaxQueueSize), otherwise events are dropped,
	// not delayed.
	MaxQueueSize int

	// Verbose enables more frequent and detailed debug logging through Logger.
	Verbose bool

	// RetryAfter returns the delay before retrying a failed batch upload. The int
	// argument is the retry attempt number. If nil, DefaultBackoff().Duration is used.
	RetryAfter func(int) time.Duration

	// MaxRetries is the maximum number of retries after the first send attempt.
	// It must be in [0,9]. If nil, it defaults to 3 retries (4 total attempts).
	MaxRetries *int

	// ShutdownTimeout is the maximum time Close waits for in-flight messages to be
	// sent. If zero or negative, Close waits indefinitely for backward compatibility.
	ShutdownTimeout time.Duration

	// BatchUploadTimeout is the timeout for uploading one batch to the /batch/
	// endpoint. If zero, it defaults to DefaultBatchUploadTimeout.
	BatchUploadTimeout time.Duration

	// BatchSubmitTimeout is the maximum time to wait when submitting a batch to the
	// worker pool while its queue is full. If zero, it defaults to
	// DefaultBatchSubmitTimeout. Set a negative duration for non-blocking behavior
	// that drops immediately when the queue is full.
	BatchSubmitTimeout time.Duration

	// MaxEnqueuedRequests is the maximum number of batches waiting for upload.
	// When the queue is full, new batches are dropped and the failure callback is
	// invoked. If zero, it defaults to DefaultMaxEnqueuedRequests.
	MaxEnqueuedRequests int

	// Compression selects the compression mode for batch payloads. CompressionGzip
	// compresses payloads and adds the appropriate headers/query params. If zero,
	// it defaults to CompressionNone.
	Compression CompressionMode

	// CaptureMode selects the capture wire protocol. It defaults to
	// CaptureModeLegacy (POST /batch/). Set CaptureModeAnalyticsV1 to opt into
	// POST /i/v1/analytics/events.
	CaptureMode CaptureMode

	// AppHost is the PostHog app host that Client.Emails sends to, such as
	// https://posthog.example.com for a self-hosted instance. If empty, a
	// PostHog Cloud Endpoint maps to its region's app host, us.posthog.com or
	// eu.posthog.com. Any other Endpoint may be a reverse proxy for ingestion,
	// so email requests never go there: without AppHost, they fail with the
	// code missing_app_host. It must use https unless AllowInsecureAppHost is
	// set. When AppHost is set, every request that carries SecretKey goes to
	// it: email requests, flag definitions for local evaluation, and remote
	// config payloads. Without AppHost, flag requests use Endpoint.
	AppHost string

	// AllowInsecureAppHost lets Client.Emails send to an http AppHost, such as
	// http://localhost:8010 during local development, and upload attachments
	// to an http file storage URL. Email requests carry SecretKey and the
	// email itself, so over http both travel unencrypted.
	AllowInsecureAppHost bool

	// EmailRequestTimeout is the timeout of each Client.Emails request to
	// PostHog. If zero, it defaults to DefaultEmailRequestTimeout. Uploading
	// an attachment to file storage isn't such a request: each upload may take
	// up to 15 minutes, the life of its upload URL. Bound a whole Send with
	// its context.
	EmailRequestTimeout time.Duration

	// EmailRequestMaxRetries is the number of retries of a Client.Emails
	// request after its first attempt, and of each attachment upload, 0 to 9.
	// If nil, it defaults to DefaultEmailRequestMaxRetries. Set Ptr(0) when a
	// job runner already retries the send, and pass an IdempotencyKey that
	// names the email.
	EmailRequestMaxRetries *int

	// MigratedFrom names the email provider your sends moved from, such as
	// "resend". Client.Emails sends it as the X-PostHog-Migrated-From header.
	MigratedFrom string
}
```

Config carries configuration options used when constructing a Client with NewWithConfig.

Each exported field's zero value is either meaningful or replaced by the default documented on that field.

#### `Config.GetDisableGeoIP`

```go
func (c Config) GetDisableGeoIP() bool
```

GetDisableGeoIP instructs the client to set $geoip\_disable on event properties or feature flag requests. It is on by default as Go is mainly used on server side and to be compatible with posthog-python.

#### `Config.GetIsServer`

```go
func (c Config) GetIsServer() bool
```

GetIsServer reports whether events should include the $is\_server property. It is on by default because posthog-go is mainly used server-side; set Config.IsServer to Ptr(false) for CLI/client usage to omit $is\_server.

#### `Config.Validate`

```go
func (c *Config) Validate() error
```

Validate verifies that fields that don't have zero-values are set to valid values, returns an error describing the problem if a field was invalid.

### `posthog.New`

```go
func New(apiKey string) Client
```

New creates a Client with the default Config and the provided PostHog project API key.

The apiKey parameter is trimmed before use. If it is empty, New returns a no-op client whose methods return default values and ErrSDKDisabled where applicable.

### `posthog.NewWithConfig`

```go
func NewWithConfig(apiKey string, config Config) (cli Client, err error)
```

NewWithConfig creates a Client with the provided PostHog project API key and Config.

The apiKey, Config.Endpoint, Config.SecretKey, and Config.PersonalApiKey values are trimmed before use. It returns a ConfigError when config contains invalid values such as negative intervals or out-of-range retry settings; in that case the returned Client is nil. If apiKey is empty after trimming, NewWithConfig returns a no-op client and nil error.

## Capture

### `Capture`

```go
type Capture struct {
	// Type is reserved for SDK serialization and is overwritten by Enqueue.
	// Deprecated: PostHog ignores the top-level type field on capture events. Use Event for
	// the captured event name.
	Type string
	// Uuid is an optional event UUID. If empty, Enqueue generates a random UUID.
	// If set, it must be a valid UUID; invalid values are replaced with a generated UUID.
	// Set it only when you need idempotency, for example to prevent duplicate events.
	Uuid string
	// DistinctId identifies the user or entity that performed Event.
	// When using EnqueueWithContext, this can be inherited from RequestContext.
	DistinctId string
	// Event is the event name to capture. It must be non-empty.
	Event string
	// Timestamp is the event timestamp. UTC is preferred; non-UTC values are
	// converted to the equivalent UTC instant. If zero, Enqueue uses the current time.
	Timestamp time.Time
	// Properties are event properties. Enqueue merges request context properties
	// and Config.DefaultEventProperties into this map before sending.
	Properties Properties
	// Groups associates the event with group analytics groups.
	Groups Groups
	// SendFeatureFlags requests legacy feature flag enrichment on this event.
	// Deprecated: Prefer Client.EvaluateFlags and pass the returned snapshot via Flags.
	// Flags writes the canonical $feature/<key> and $active_feature_flags properties.
	SendFeatureFlags SendFeatureFlagsValue
	// Flags, when set, attaches $feature/<key> and $active_feature_flags
	// properties from a snapshot returned by Client.EvaluateFlags. It is
	// preferred over SendFeatureFlags: the snapshot guarantees the event
	// carries the exact values the application branched on and avoids a
	// hidden /flags request on every capture. Flags takes precedence when
	// both are set.
	Flags *FeatureFlagEvaluations
	// IsServer controls whether the event includes the $is_server property.
	// Enqueue overwrites it from Config.GetIsServer.
	IsServer bool
	// Library, when non-empty, replaces SDKName as this event's $lib so an
	// integration built on posthog-go is attributed to itself without
	// relabelling the application's other events. $lib_version stays the
	// posthog-go version. CaptureModeAnalyticsV1 ignores it, because the server takes
	// $lib from the per-request PostHog-Sdk-Info header there.
	Library string
}
```

Capture represents a custom event to send to PostHog. Enqueue validates Event and DistinctId (or obtains DistinctId from request context), fills Type, Uuid, and Timestamp, merges Config.DefaultEventProperties, and queues the event for a future batch upload.

#### `Capture.APIfy`

```go
func (msg Capture) APIfy() APIMessage
```

APIfy converts a Capture message into the PostHog batch API representation.

#### `Capture.Validate`

```go
func (msg Capture) Validate() error
```

Validate checks that the capture message has a non-empty Event and DistinctId.

### `EnqueueClient.Enqueue`

```go
Enqueue(Message) error
```

Enqueue queues a message to be sent by the client when the conditions for a batch upload are met. This is the main method you'll be using, a typical flow would look like this:

```go
client := posthog.New(apiKey)
...
client.Enqueue(posthog.Capture{ ... })
...
client.Close()
```

Enqueue returns an error if the message could not be queued, which happens when the client is closed, the message is invalid, or the in-memory queue is full (ErrQueueFull) -- in the latter case the message is dropped rather than blocking the caller. A full-queue drop is reported only through this returned error, not through Callback.Failure.

Bulk or backfill workloads that can enqueue faster than the client uploads should check the returned error for ErrQueueFull and throttle or retry (or raise Config.MaxQueueSize); otherwise events are dropped, not delayed.

### `posthog.EnqueueWithContext`

```go
func EnqueueWithContext(ctx context.Context, client EnqueueClient, msg Message) error
```

EnqueueWithContext queues a message and applies any PostHog request context attached to ctx. Use this from HTTP handlers with r.Context() when NewRequestContextMiddleware is installed.

## Identify

### `Identify`

```go
type Identify struct {
	// Type is reserved for SDK serialization and is overwritten by Enqueue.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string
	// Uuid is an optional event UUID. If empty, Enqueue generates a random UUID.
	// If set, it must be a valid UUID; invalid values are replaced with a generated UUID.
	Uuid string

	// DistinctId is the user distinct ID whose person profile should be updated.
	DistinctId string
	// Timestamp is the event timestamp. UTC is preferred; non-UTC values are
	// converted to the equivalent UTC instant. If zero, Enqueue uses the current time.
	Timestamp time.Time
	// Properties are sent as the $set person properties for DistinctId.
	Properties Properties
	// DisableGeoIP controls whether this identify event disables GeoIP lookup.
	// Enqueue overwrites it from Config.GetDisableGeoIP.
	DisableGeoIP bool
	// IsServer controls whether the event includes the $is_server property.
	// Enqueue overwrites it from Config.GetIsServer.
	IsServer bool
}
```

Identify represents an identify call that sets person properties for a user. Enqueue validates that DistinctId is set, fills Type, Uuid, Timestamp, and DisableGeoIP, then sends the message as a $identify event.

#### `Identify.APIfy`

```go
func (msg Identify) APIfy() APIMessage
```

APIfy converts an Identify message into the PostHog batch API representation.

#### `Identify.Validate`

```go
func (msg Identify) Validate() error
```

Validate checks that the identify message has a DistinctId.

## Alias

### `Alias`

```go
type Alias struct {
	// Type is reserved for SDK serialization and is overwritten by Enqueue.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string
	// Uuid is an optional event UUID. If empty, Enqueue generates a random UUID.
	// If set, it must be a valid UUID; invalid values are replaced with a generated UUID.
	Uuid string

	// Alias is the alternate distinct ID to attach to DistinctId.
	Alias string
	// DistinctId is the existing user distinct ID that Alias should resolve to.
	DistinctId string
	// Timestamp is the event timestamp. UTC is preferred; non-UTC values are
	// converted to the equivalent UTC instant. If zero, Enqueue uses the current time.
	Timestamp time.Time
	// DisableGeoIP controls whether this alias event disables GeoIP lookup.
	// Enqueue overwrites it from Config.GetDisableGeoIP.
	DisableGeoIP bool
	// IsServer controls whether the event includes the $is_server property.
	// Enqueue overwrites it from Config.GetIsServer.
	IsServer bool
}
```

Alias represents an alias call that links another distinct ID to an existing user. Enqueue validates that DistinctId and Alias are both set, fills Type, Uuid, Timestamp, and DisableGeoIP, then sends the message as a $create\_alias event.

#### `Alias.APIfy`

```go
func (msg Alias) APIfy() APIMessage
```

APIfy converts an Alias message into the PostHog batch API representation.

#### `Alias.Validate`

```go
func (msg Alias) Validate() error
```

Validate checks that the alias message has both DistinctId and Alias set.

## Capture exception

### `Exception`

```go
type Exception struct {
	// Type is reserved for SDK serialization and is overwritten by Enqueue.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string
	// Uuid is an optional event UUID. If empty, Enqueue generates a random UUID.
	// If set, it must be a valid UUID; invalid values are replaced with a generated UUID.
	Uuid string

	// DistinctId identifies the user or entity associated with the exception.
	// When using EnqueueWithContext, this can be inherited from RequestContext.
	DistinctId string
	// DebugImages lists the binary images referenced by "native" stack
	// frames, sent as $debug_images for server-side symbolication.
	DebugImages []DebugImage
	// Timestamp is the event timestamp. UTC is preferred; non-UTC values are
	// converted to the equivalent UTC instant. If zero, Enqueue uses the current time.
	Timestamp time.Time
	// Properties are custom event properties flattened into the exception event.
	Properties Properties
	// DisableGeoIP controls whether this exception event disables GeoIP lookup.
	// Enqueue overwrites it from Config.GetDisableGeoIP.
	DisableGeoIP bool
	// IsServer controls whether the event includes the $is_server property.
	// Enqueue overwrites it from Config.GetIsServer.
	IsServer bool
	// Library, when non-empty, replaces SDKName as this event's $lib.
	// See Capture.Library.
	Library string

	// ExceptionList is the list of exception items sent as $exception_list. It must be non-empty.
	ExceptionList []ExceptionItem
	// ExceptionFingerprint optionally overrides PostHog's default exception grouping fingerprint.
	ExceptionFingerprint *string
}
```

Exception represents an error tracking exception event. Enqueue validates DistinctId and ExceptionList (or obtains DistinctId from request context), fills Type, Uuid, Timestamp, and DisableGeoIP, then sends the message as a $exception event.

#### `Exception.APIfy`

```go
func (msg Exception) APIfy() APIMessage
```

APIfy converts an Exception message into the PostHog batch API representation.

#### `Exception.Validate`

```go
func (msg Exception) Validate() error
```

Validate checks that the exception has a DistinctId and at least one valid ExceptionItem.

#### `posthog.NewDefaultException`

```go
func NewDefaultException(
	timestamp time.Time,
	distinctID, title, description string,
) Exception
```

NewDefaultException builds an Exception with a default stack trace.

The timestamp parameter becomes Exception.Timestamp; UTC is preferred, and Enqueue converts non-UTC values to the equivalent UTC instant. distinctID becomes Exception.DistinctId, title becomes the first ExceptionItem.Type, and description becomes the first ExceptionItem.Value. The returned Exception is ready to pass to Client.Enqueue. Build Exception manually if you need custom properties, fingerprints, mechanisms, or stack frames.

### `posthog.NewSlogCaptureHandler`

```go
func NewSlogCaptureHandler(next slog.Handler, client EnqueueClient, opts ...SlogOption) *SlogCaptureHandler
```

NewSlogCaptureHandler wraps next and mirrors qualifying slog records to PostHog.

The next parameter receives all records as your normal handler. The client parameter receives captured Exception messages. The opts parameters customize capture level, distinct ID resolution, stack traces, descriptions, fingerprints, and extra properties.

You typically wrap your existing handler:

```go
client, err := posthog.NewWithConfig(...)
// error handling and `defer client.Close()` call
base := slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: slog.LevelInfo})
logger := slog.New(posthog.NewSlogCaptureHandler(base, client,
  posthog.WithDistinctIDFn(func(ctx context.Context, r slog.Record) string {
    return "my-user-id" // or pull from ctx
  }),
))
```

## Emails

### `Client.Emails`

```go
Emails() Emails
```

Emails sends transactional email from PostHog email templates or from content your code rendered, and reads the status of each email it sent. It needs Config.SecretKey, a project secret API key with the transactional\_email:write scope. Close waits for email requests in flight, and a request after Close fails with the code client\_closed.

## Flush

### `Client.Flush`

```go
Flush() error
```

Flush sends queued messages and waits for the current delivery cycle without closing the client. Retryable failures end the cycle while the transport retains the events for its scheduled retry. Flush does not bypass retry backoff. Delivery failures use the existing retry policy and Callback.Failure; a nil result does not guarantee successful ingestion. Use FlushWithContext to bound the wait. Do not call a blocking Flush from a delivery callback, which is itself part of the delivery cycle.

### `Client.FlushWithContext`

```go
FlushWithContext(context.Context) error
```

FlushWithContext is Flush with a caller-controlled deadline. Cancellation stops only this caller's wait, not delivery or future use of the client. Messages accepted before the call are covered; concurrent Enqueue calls may be included in this cycle or a later one. Calls after Close return ErrClosed.

## Get feature flag

### `Client.GetFeatureFlag`

```go
GetFeatureFlag(FeatureFlagPayload) (interface{}, error)
```

GetFeatureFlag evaluates one feature flag for a user. It returns a variant string for multivariate flags, true or false for boolean flags, false with nil error when the flag is missing/disabled, and an error for evaluation failures. Deprecated: Prefer EvaluateFlags for new code.

## Get feature flag payload

### `Client.GetFeatureFlagPayload`

```go
GetFeatureFlagPayload(FeatureFlagPayload) (string, error)
```

GetFeatureFlagPayload returns the payload for the matching flag value, or an empty string when no payload is configured or the flag is missing/disabled. Deprecated: Use GetFeatureFlagResult instead, which returns both the flag value and payload while properly tracking feature flag usage.

## Get feature flag result

### `Client.GetFeatureFlagResult`

```go
GetFeatureFlagResult(FeatureFlagPayload) (*FeatureFlagResult, error)
```

GetFeatureFlagResult evaluates one feature flag and returns its value and payload together. Use this instead of calling GetFeatureFlag and GetFeatureFlagPayload separately. It returns ErrFlagNotFound when the flag cannot be found or evaluated and ErrNoSecretKey when OnlyEvaluateLocally is true without SecretKey or a FlagDefinitionCacheProvider.

## Get feature flags

### `Client.GetAllFlags`

```go
GetAllFlags(FeatureFlagPayloadNoKey) (map[string]interface{}, error)
```

GetAllFlags evaluates all flags for a user. Returned values are booleans for boolean flags and strings for multivariate variants. It returns ErrNoSecretKey when OnlyEvaluateLocally is true without SecretKey or a FlagDefinitionCacheProvider.

## Evaluate flags

### `Client.EvaluateFlags`

```go
EvaluateFlags(EvaluateFlagsPayload) (*FeatureFlagEvaluations, error)
```

EvaluateFlags returns a snapshot of feature-flag evaluations for the given distinct\_id using at most one /flags request. Returns ErrNoDistinctID if DistinctId is empty. Pass the returned snapshot to a Capture event via Capture.Flags to attach $feature/<key> properties without another network call. Calls to IsEnabled and GetFlag on the snapshot fire deduped $feature\_flag\_called events; GetFlagPayload does not.

If FlagKeys contains a key missing from loaded local definitions, EvaluateFlags includes it in the remote /flags fallback unless OnlyEvaluateLocally is true. If the remote request fails after some flags were resolved locally, EvaluateFlags returns a non-nil snapshot containing the locally-evaluated flags alongside the error so the caller can still branch on what was resolved. If OnlyEvaluateLocally is true and neither SecretKey nor a FlagDefinitionCacheProvider is configured, returns ErrNoSecretKey.

### `EvaluateFlagsPayload`

```go
type EvaluateFlagsPayload struct {
	// DistinctId is the user distinct ID to evaluate flags for. It is required
	// unless EvaluateFlagsWithContext can read one from RequestContext.
	DistinctId string
	// DeviceId optionally provides a device_id for remote /flags requests and event deduplication.
	DeviceId *string
	// Groups supplies group identifiers for group-targeted flags.
	Groups Groups
	// PersonProperties overrides person properties used during flag evaluation.
	PersonProperties Properties
	// GroupProperties overrides group properties used during flag evaluation, keyed by group type.
	GroupProperties map[string]Properties
	// OnlyEvaluateLocally prevents fallback to remote /flags requests. Flags
	// that cannot be resolved from loaded local definitions are omitted, and
	// FeatureFlagEvaluations.UnresolvedFlags lists them with a reason.
	OnlyEvaluateLocally bool
	// DisableGeoIP, when non-nil, overrides the client-level DisableGeoIP for
	// this evaluation only.
	DisableGeoIP *bool
	// FlagKeys restricts local evaluation, the remote request, and the returned
	// snapshot to the named flags. Nil evaluates all flags, while an explicitly
	// empty slice returns an empty snapshot without evaluating flags. A requested
	// key missing from loaded local definitions triggers a /flags fallback unless
	// OnlyEvaluateLocally is true. EvaluateFlags does not cache snapshots, so a
	// key that does not exist remotely can trigger a request on each call.
	// Use FeatureFlagEvaluations.Only to filter an existing snapshot in memory.
	FlagKeys []string
}
```

EvaluateFlagsPayload is the input to Client.EvaluateFlags.

### `posthog.EvaluateFlagsWithContext`

```go
func EvaluateFlagsWithContext(ctx context.Context, client Client, payload EvaluateFlagsPayload) (*FeatureFlagEvaluations, error)
```

EvaluateFlagsWithContext evaluates feature flags and uses the request-scoped distinct ID attached to ctx when payload.DistinctId is empty. It does not generate personless IDs: feature flag evaluation requires a stable distinct ID and returns ErrNoDistinctID if neither payload nor ctx has one.

## Group identify

### `GroupIdentify`

```go
type GroupIdentify struct {
	// Type is the group type, such as "company" or "organization".
	Type string
	// Key is the group key or ID within the group type.
	Key string
	// Uuid is an optional event UUID. If empty, Enqueue generates a random UUID.
	// If set, it must be a valid UUID; invalid values are replaced with a generated UUID.
	Uuid string

	// DistinctId is accepted for compatibility but the wire payload uses a generated group distinct ID.
	DistinctId string
	// Timestamp is the event timestamp. UTC is preferred; non-UTC values are
	// converted to the equivalent UTC instant. If zero, Enqueue uses the current time.
	Timestamp time.Time
	// Properties are sent as the $group_set properties for the group.
	Properties Properties
	// DisableGeoIP controls whether this group-identify event disables GeoIP lookup.
	// Enqueue overwrites it from Config.GetDisableGeoIP.
	DisableGeoIP bool
	// IsServer controls whether the event includes the $is_server property.
	// Enqueue overwrites it from Config.GetIsServer.
	IsServer bool
}
```

GroupIdentify represents a group analytics call that sets properties on a group. Enqueue validates Type and Key, fills Uuid, Timestamp, and DisableGeoIP, then sends the message as a $groupidentify event.

#### `GroupIdentify.APIfy`

```go
func (msg GroupIdentify) APIfy() APIMessage
```

APIfy converts a GroupIdentify message into the PostHog batch API representation.

#### `GroupIdentify.Validate`

```go
func (msg GroupIdentify) Validate() error
```

Validate checks that the group identify message has Type and Key set.

## Is feature enabled

### `Client.IsFeatureEnabled`

```go
IsFeatureEnabled(FeatureFlagPayload) (interface{}, error)
```

IsFeatureEnabled evaluates one feature flag for a user and returns the same value as GetFeatureFlag: a variant string for multivariate flags or a bool for boolean flags. The FeatureFlagPayload parameter supplies the flag key, distinct ID, optional groups/properties, and evaluation options. Deprecated: Prefer EvaluateFlags for new code.

## Reload feature flags

### `Client.ReloadFeatureFlags`

```go
ReloadFeatureFlags() error
```

ReloadFeatureFlags forces a reload of feature flags. If neither SecretKey nor a FlagDefinitionCacheProvider is configured, returns ErrNoSecretKey.

## Shutdown

### `Client.Close`

```go
Close() error
```

Close gracefully shuts down the client and flushes pending messages. If Config.ShutdownTimeout is positive, Close uses it as the shutdown deadline; otherwise it waits indefinitely. Repeated calls return ErrClosed.

### `Client.CloseWithContext`

```go
CloseWithContext(context.Context) error
```

CloseWithContext gracefully shuts down the client with the provided context. The context can be used to control the shutdown deadline.

## Before send hook

### `BeforeSendFunc`

```go
type BeforeSendFunc func(Message) Message
```

BeforeSendFunc is called before a message is converted to the PostHog API format. It can return a modified message, or nil to drop the message. If the hook panics, returns an invalid message, or returns a different message type, the message is dropped.

The SDK passes an isolated copy of SDK-owned mutable fields where practical: Properties and Groups clone common JSON-like maps and slices, and Exception clones its exception list, stack traces, mechanisms, fingerprint, and debug images. Arbitrary reference values stored inside Properties or Groups (for example, pointers or custom mutable structs held as interface{} values) are not deep-cloned and can still share state with the caller.

## SDK utils

### `Client.GetRemoteConfigPayload`

```go
GetRemoteConfigPayload(string) (string, error)
```

GetRemoteConfigPayload returns the decrypted payload for a remote config flag key. It requires Config.SecretKey and returns ErrNoSecretKey when missing.

### `posthog.NewRequestContextMiddleware`

```go
func NewRequestContextMiddleware(next http.Handler, opts ...RequestContextOption) http.Handler
```

NewRequestContextMiddleware wraps an http.Handler with PostHog request-context extraction.

The middleware always attaches safe request metadata to r.Context(). By default it also reads X-PostHog-Distinct-Id and X-PostHog-Session-Id into request-scoped analytics context. Use EnqueueWithContext(r.Context(), ...) for captures inside the request so this metadata is applied.

### `posthog.Ptr`

```go
func Ptr[T any](v T) *T
```

Ptr returns a pointer to v.

### `posthog.SimpleInAppDecider`

```go
func SimpleInAppDecider(frame runtime.Frame) bool
```

SimpleInAppDecider is a basic InAppDecider that classifies frames by file path. It excludes vendored modules, module cache paths, and Go toolchain paths.

### `posthog.WithFreshRequestContext`

```go
func WithFreshRequestContext(ctx context.Context, requestContext RequestContext) context.Context
```

WithFreshRequestContext returns a child context with PostHog request metadata attached without inheriting any existing PostHog request context from the parent.

### `posthog.WithRequestContext`

```go
func WithRequestContext(ctx context.Context, requestContext RequestContext) context.Context
```

WithRequestContext returns a child context with PostHog request metadata attached. Existing PostHog request context values are inherited: non-empty DistinctId and SessionId override the parent values, and Properties are merged with child properties taking precedence.

### Constants

```go
const (
	// SDKName is the library identifier sent in event metadata.
	SDKName = "posthog-go"

	// DefaultEndpoint is the default PostHog API host used when Config.Endpoint is empty.
	DefaultEndpoint = "https://us.i.posthog.com"

	// DefaultInterval is the default flush interval used when Config.Interval is zero.
	DefaultInterval = 5 * time.Second

	// DefaultFeatureFlagsPollingInterval is the default local feature flag reload interval.
	DefaultFeatureFlagsPollingInterval = 5 * time.Minute

	// DefaultFeatureFlagRequestTimeout is the default timeout for feature flag requests.
	DefaultFeatureFlagRequestTimeout = 3 * time.Second

	// DefaultBatchSize is the default batch size used when Config.BatchSize is zero.
	DefaultBatchSize = 100

	// DefaultMaxAttempts is the total number of capture delivery attempts (1
	// initial + retries) used when Config.MaxRetries is unset or out of range.
	// Chosen to match the cross-SDK Capture V1 parity standard (posthog-rs
	// defaults to the same envelope). Applies to both the v0 and v1 send paths.
	DefaultMaxAttempts = 4

	// DefaultBatchUploadTimeout is the default timeout for uploading batched
	// events to the /batch/ endpoint.
	DefaultBatchUploadTimeout = 10 * time.Second

	// DefaultBatchSubmitTimeout is the default timeout for submitting batches
	// to the worker pool when the queue is full. This allows workers time to
	// complete during transient latency spikes, reducing unnecessary data loss.
	DefaultBatchSubmitTimeout = 100 * time.Millisecond

	// DefaultMaxEnqueuedRequests is the default maximum number of batches that
	// can be queued for sending.
	DefaultMaxEnqueuedRequests = 1000

	// DefaultMaxQueueSize is the default in-memory message queue capacity used when
	// Config.MaxQueueSize is zero. It matches the posthog-python, posthog-rs, and
	// posthog-node defaults so backend SDKs behave consistently under bursty load.
	DefaultMaxQueueSize = 10000

	// DefaultEmailRequestTimeout is the default timeout of each Client.Emails request.
	DefaultEmailRequestTimeout = 15 * time.Second

	// DefaultEmailRequestMaxRetries is the default number of retries of a
	// Client.Emails request after its first attempt.
	DefaultEmailRequestMaxRetries = 2
)
```

```go
const (
	// FeatureFlagErrorErrorsWhileComputing indicates the server returned errorsWhileComputingFlags=true
	FeatureFlagErrorErrorsWhileComputing = "errors_while_computing_flags"

	// FeatureFlagErrorFlagMissing indicates the requested flag was not in the API response
	FeatureFlagErrorFlagMissing = "flag_missing"

	// FeatureFlagErrorLocalEvaluationInconclusive indicates the flag has a loaded local
	// definition, but neither local evaluation nor a remote fallback resolved it
	FeatureFlagErrorLocalEvaluationInconclusive = "local_evaluation_inconclusive"

	// FeatureFlagErrorEvaluationFailed indicates the flag was present but failed to evaluate due to a transient server error
	FeatureFlagErrorEvaluationFailed = "evaluation_failed"

	// FeatureFlagErrorQuotaLimited indicates rate/quota limit was exceeded
	FeatureFlagErrorQuotaLimited = "quota_limited"

	// FeatureFlagErrorTimeout indicates request timed out
	FeatureFlagErrorTimeout = "timeout"

	// FeatureFlagErrorConnectionError indicates network connectivity issue
	FeatureFlagErrorConnectionError = "connection_error"

	// FeatureFlagErrorUnknownError indicates an unexpected error occurred
	FeatureFlagErrorUnknownError = "unknown_error"

	// FeatureFlagErrorAPIErrorPrefix is the prefix for API errors with status codes
	FeatureFlagErrorAPIErrorPrefix = "api_error_"
)
```

Feature flag error type constants for the $feature\_flag\_error property. These values are sent in analytics events to track flag evaluation failures. They should not be changed without considering impact on existing dashboards and queries that filter on these values.

```go
const (
	// CACHE_DEFAULT_SIZE is the number of feature flag calls tracked for local deduplication.
	CACHE_DEFAULT_SIZE = 300_000

	// DefaultIdleConns is the default max idle connections for the HTTP client.
	DefaultIdleConns = 100
	// DefaultIdleConnsPerHost is the default max idle connections per host.
	// This is higher than http.DefaultTransport's value of 2 to reduce
	// connection churn when sending batches.
	DefaultIdleConnsPerHost = 10
)
```

```go
const (
	// HeaderPostHogDistinctID is the HTTP header used to propagate a PostHog distinct ID.
	HeaderPostHogDistinctID = "X-PostHog-Distinct-Id"
	// HeaderPostHogSessionID is the HTTP header used to propagate a PostHog session ID.
	HeaderPostHogSessionID = "X-PostHog-Session-Id"
)
```

```go
const (
	// LONG_SCALE is the denominator used to normalize feature flag hash values.
	LONG_SCALE = 0xfffffffffffffff
)
```

```go
const Version = "1.44.1"
```

Version of the client.

### Variables

```go
var (
	// This error is returned by methods of the `Client` interface when they are
	// called after the client was already closed.
	ErrClosed = errors.New("the client was already closed")

	// This error is used to notify the application that too many requests are
	// already being sent and no more messages can be accepted.
	ErrTooManyRequests = errors.New("too many requests are already in-flight")

	// This error is used to notify the client callbacks that a message send
	// failed because the JSON representation of a message exceeded the upper
	// limit.
	ErrMessageTooBig = errors.New("the message exceeds the maximum allowed size")

	// ErrNoSecretKey is returned when a SecretKey is required for the requested
	// operation but was not configured.
	ErrNoSecretKey = errors.New("no SecretKey provided")

	// ErrNoPersonalAPIKey is a deprecated alias for ErrNoSecretKey. It refers to
	// the same error value, so errors.Is checks against either name still match.
	//
	// Deprecated: use ErrNoSecretKey.
	ErrNoPersonalAPIKey = ErrNoSecretKey

	// ErrNoDistinctID is returned when distinct_id is required for the requested
	// operation but was not provided.
	ErrNoDistinctID = errors.New("no distinct_id provided")

	// ErrQueueFull is returned by Enqueue/EnqueueWithContext when the in-memory
	// message queue is full. The message is dropped (not retried) and the drop is
	// reported only through this returned error, not through Callback.Failure.
	ErrQueueFull = errors.New("the message queue is full, the message was dropped")

	// ErrSDKDisabled is returned when the SDK is disabled because the project API key is missing.
	ErrSDKDisabled = errors.New("posthog SDK is disabled because project API key is missing")
)
```

```go
var ErrFlagNotFound = errors.New("feature flag not found")
```

ErrFlagNotFound is returned when a feature flag does not exist or is disabled. Use errors.Is(err, ErrFlagNotFound) to check for this error.

## `FeatureFlagEvaluations`

```go
type FeatureFlagEvaluations struct {
	// contains filtered or unexported fields
}
```

FeatureFlagEvaluations is a snapshot of feature-flag evaluations for a single distinct\_id, returned by Client.EvaluateFlags. It is the recommended way to evaluate many flags for a single user with a single network request: the snapshot can power any number of IsEnabled / GetFlag checks and can be attached to a Capture event via Capture.Flags so the event carries the exact values the application branched on, with no additional /flags call.

Calls to IsEnabled and GetFlag fire $feature\_flag\_called (deduped per (distinct\_id, key, device\_id)). GetFlagPayload does not fire an event.

### `FeatureFlagEvaluations.GetFlag`

```go
func (e *FeatureFlagEvaluations) GetFlag(key string) interface{}
```

GetFlag returns the value of the flag: a string for multivariate flags, true or false for boolean flags, or nil for unknown flags. The first call for a given key fires $feature\_flag\_called with full evaluation metadata; subsequent calls with the same response are deduped.

### `FeatureFlagEvaluations.GetFlagPayload`

```go
func (e *FeatureFlagEvaluations) GetFlagPayload(key string) string
```

GetFlagPayload returns the raw JSON payload string for the flag, or "" if no payload is configured or the flag is unknown. Unlike IsEnabled and GetFlag, it does not record an access and does not fire an event.

### `FeatureFlagEvaluations.IsEnabled`

```go
func (e *FeatureFlagEvaluations) IsEnabled(key string) bool
```

IsEnabled reports whether the flag is enabled for this snapshot's user. Unknown flags return false. The first call for a given key fires $feature\_flag\_called with full evaluation metadata; subsequent calls with the same response are deduped against the client's per-distinct\_id cache.

### `FeatureFlagEvaluations.Keys`

```go
func (e *FeatureFlagEvaluations) Keys() []string
```

Keys returns the sorted list of evaluated flag keys.

### `FeatureFlagEvaluations.Only`

```go
func (e *FeatureFlagEvaluations) Only(keys []string) *FeatureFlagEvaluations
```

Only returns a filtered copy of this snapshot keeping only the named flags that were actually evaluated. Unknown keys are dropped with a warning.

The returned snapshot tracks access independently from the receiver.

### `FeatureFlagEvaluations.OnlyAccessed`

```go
func (e *FeatureFlagEvaluations) OnlyAccessed() *FeatureFlagEvaluations
```

OnlyAccessed returns a filtered copy of this snapshot containing only the flags that were accessed via IsEnabled or GetFlag before this call.

The method honors its name: if nothing has been accessed yet, the returned snapshot is empty. Pre-access the flags you want to attach before calling.

The returned snapshot tracks access independently from the receiver; further accesses on the child do not influence what the parent sees.

### `FeatureFlagEvaluations.UnresolvedFlags`

```go
func (e *FeatureFlagEvaluations) UnresolvedFlags() map[string]UnresolvedFlagReason
```

UnresolvedFlags returns the flags that have a loaded local definition but that neither local evaluation nor a remote fallback resolved, mapped to the reason local evaluation was inconclusive. These flags are absent from Keys, IsEnabled returns false and GetFlag returns nil for them. Reading this does not record an access and does not fire an event. The returned map is a copy.

Snapshots returned by Only and OnlyAccessed have no unresolved flags.

## Types

### `APIError`

```go
type APIError struct {
	// StatusCode is the HTTP status code returned by the PostHog API.
	StatusCode int
	// Message is the error message returned by or derived from the API response.
	Message string
}
```

APIError represents an HTTP API error with a status code. This allows classifyError to generate api\_error\_{status} strings.

#### `APIError.Error`

```go
func (e *APIError) Error() string
```

Error returns the API error message.

#### `posthog.NewAPIError`

```go
func NewAPIError(statusCode int, message string) *APIError
```

NewAPIError creates an APIError with the given HTTP status code and message.

### `APIMessage`

```go
type APIMessage interface{}
```

APIMessage is a wire-format message produced by Message.APIfy and passed to callbacks. Legacy API message structs may still expose top-level fields such as type, library, library\_version, and send\_feature\_flags for compatibility. Capture ingestion uses event plus properties such as $lib, $lib\_version, $feature/<key>, and $active\_feature\_flags instead.

### `AliasInApi`

```go
type AliasInApi struct {
	// Type is the legacy message type sent to the batch API.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string `json:"type"`
	// Uuid is the valid event UUID sent to the batch API.
	Uuid string `json:"uuid"`
	// Library is the SDK name sent to the batch API.
	Library string `json:"library"`
	// LibraryVersion is the SDK version sent to the batch API.
	LibraryVersion string `json:"library_version"`
	// Timestamp is the event timestamp sent to the batch API in UTC.
	Timestamp time.Time `json:"timestamp"`

	// Properties contains alias-specific event properties.
	Properties AliasInApiProperties `json:"properties"`

	// Event is always $create_alias for Alias messages.
	Event string `json:"event"`
}
```

AliasInApi is the wire-format payload produced from an Alias message.

### `AliasInApiProperties`

```go
type AliasInApiProperties struct {
	// DistinctId is the canonical user distinct ID.
	DistinctId string `json:"distinct_id"`
	// Alias is the alternate distinct ID being linked to DistinctId.
	Alias string `json:"alias"`
	// Lib is the SDK name sent as $lib.
	Lib string `json:"$lib"`
	// LibVersion is the SDK version sent as $lib_version.
	LibVersion string `json:"$lib_version"`
	// IsServer marks the event as originating from a server-side SDK.
	// Omitted entirely when nil (Config.IsServer resolved to false).
	IsServer *bool `json:"$is_server,omitempty"`
	// DisableGeoIP is sent as $geoip_disable when GeoIP lookup is disabled.
	DisableGeoIP bool `json:"$geoip_disable,omitempty"`
}
```

AliasInApiProperties is the wire-format properties object for an Alias message.

#### `AliasInApiProperties.ToProperties`

```go
func (ctx AliasInApiProperties) ToProperties() Properties
```

### `Backoff`

```go
type Backoff struct {
	// contains filtered or unexported fields
}
```

Backoff calculates exponential retry delays with optional jitter and a maximum cap.

#### `Backoff.Duration`

```go
func (b *Backoff) Duration(attempt int) time.Duration
```

Duration returns the backoff interval for the given attempt.

#### `Backoff.NewTicker`

```go
func (b *Backoff) NewTicker() *Ticker
```

NewTicker starts a ticker that waits Duration(0), Duration(1), and so on between ticks.

#### `Backoff.Sleep`

```go
func (b *Backoff) Sleep(attempt int)
```

Sleep pauses the current goroutine for the backoff interval for the given attempt.

#### `posthog.DefaultBackoff`

```go
func DefaultBackoff() *Backoff
```

DefaultBackoff creates a Backoff with the SDK's default retry policy:

```text
base: 100 milliseconds
factor: 2
jitter: 0
cap: 30 seconds
```

#### `posthog.NewBackoff`

```go
func NewBackoff(base time.Duration, factor uint8, jitter float64, cap time.Duration) *Backoff
```

NewBackoff creates a Backoff with the provided base duration, exponential factor, jitter ratio, and maximum cap duration.

### `Callback`

```go
type Callback interface {
	// Success is called for every message that was successfully sent to the API.
	Success(APIMessage)

	// Failure is called for every message that failed to be sent to the API and
	// will be discarded by the client. The error describes the send or serialization failure.
	Failure(APIMessage, error)
}
```

Callback is implemented by applications that want delivery notifications.

Callback methods are called by a client's internal goroutines. There are no guarantees about which goroutine triggers the callbacks, whether calls are made sequentially or in parallel, or whether callback order matches enqueue order.

Callback methods must return quickly and avoid long blocking operations so they do not interfere with the client's internal workflow.

### `CaptureEventError`

```go
type CaptureEventError struct {
	// EventUUID is the uuid of the rejected event (matches Capture.Uuid etc.).
	EventUUID string
	// Result is the server's per-event directive, e.g. "drop" or "retry".
	Result string
	// Details is the server-supplied explanation, when present (may be empty).
	Details string
	// Exhausted is true when the event was still retryable but the SDK ran out
	// of attempts, false for a server-directed terminal drop.
	Exhausted bool
}
```

CaptureEventError is delivered to Callback.Failure for a single event that the capture-v1 endpoint rejected: either a terminal "drop" result, or an event still asking to "retry" once the attempt budget is exhausted. Callers can use errors.As to inspect the per-event outcome.

This error type is produced exclusively on the 200-with-partial-results path — when the batch-level HTTP exchange succeeds but individual events within the batch are rejected or not persisted. It is never returned for batch-level transport failures (use CaptureRequestError for those via errors.As).

#### `CaptureEventError.Error`

```go
func (e *CaptureEventError) Error() string
```

### `CaptureInApi`

```go
type CaptureInApi struct {
	// Type is the legacy message discriminator retained for callbacks.
	// Deprecated: PostHog ignores this top-level field for capture events, so it
	// is no longer serialized. Use Event for the captured event name.
	Type string `json:"-"`
	// Uuid is the valid event UUID sent to the batch API.
	Uuid string `json:"uuid"`
	// Library is the legacy top-level SDK name retained for callbacks.
	// Deprecated: PostHog reads SDK identity from Properties["$lib"], so this
	// top-level field is no longer serialized.
	Library string `json:"-"`
	// LibraryVersion is the legacy top-level SDK version retained for callbacks.
	// Deprecated: PostHog reads SDK version from Properties["$lib_version"], so
	// this top-level field is no longer serialized.
	LibraryVersion string `json:"-"`
	// Timestamp is the event timestamp sent to the batch API in UTC.
	Timestamp time.Time `json:"timestamp"`

	// DistinctId identifies the user or entity for the event.
	DistinctId string `json:"distinct_id"`
	// Event is the captured event name.
	Event string `json:"event"`
	// Properties contains event, SDK, system, group, and feature flag properties.
	Properties Properties `json:"properties"`
	// SendFeatureFlags carries the legacy send_feature_flags value for callbacks.
	// Deprecated: PostHog ignores this top-level field, so it is no longer
	// serialized. Use Capture.Flags to send the canonical $feature/<key> and
	// $active_feature_flags properties.
	SendFeatureFlags SendFeatureFlagsValue `json:"-"`
}
```

CaptureInApi is the wire-format payload produced from a Capture message.

### `CaptureMode`

```go
type CaptureMode uint8
```

CaptureMode selects the capture wire protocol used for event ingestion.

```go
const (
	// CaptureModeLegacy sends events to the legacy POST /batch/ endpoint. This
	// is the default, so upgrading is transparent to existing callers.
	CaptureModeLegacy CaptureMode = 0
	// CaptureModeAnalyticsV1 opts into POST /i/v1/analytics/events (Bearer auth,
	// per-event results, partial retry).
	CaptureModeAnalyticsV1 CaptureMode = 1
)
```

### `CaptureRequestError`

```go
type CaptureRequestError struct {
	// StatusCode is the HTTP status, or 0 if the request never got a response.
	StatusCode int
	// Code is the machine-readable error from the response body (may be empty).
	Code string
	// Description is the human-readable error from the response body (may be empty).
	Description string
	// Err is the underlying transport or body-parse error, if any.
	Err error
}
```

CaptureRequestError is delivered to Callback.Failure when an entire capture-v1 request fails: a non-2xx status, a transport error, or a malformed 2xx body. It carries the HTTP status and any structured error body the endpoint returned, and unwraps to the underlying transport/parse error when there is one.

This error type covers batch-level failures — transport errors, terminal HTTP statuses (400/401/429/...), retryable statuses (5xx) whose retry budget is exhausted, and 2xx responses with unparseable bodies. For per-event failures within a successful batch response, see CaptureEventError.

#### `CaptureRequestError.Error`

```go
func (e *CaptureRequestError) Error() string
```

#### `CaptureRequestError.Unwrap`

```go
func (e *CaptureRequestError) Unwrap() error
```

### `CodeEmail`

```go
type CodeEmail struct {
	// To is one recipient email address.
	To string
	// TemplateKey names the email, such as "password-reset", so its metrics,
	// logs and status group under it in PostHog. Letters, digits, hyphens and
	// underscores, at most 400.
	TemplateKey string
	Subject     string
	// HTML is the HTML body. Set HTML, Text or both.
	HTML string
	// Text is the plain-text body. Without it, PostHog derives it from HTML.
	Text string
	// From is a verified sender, such as "Acme <security@example.com>".
	// Without it, PostHog sends from the project's default sender.
	From    string
	ReplyTo []string
	// Cc are bare addresses, such as "finance@example.com", that get a copy
	// the other recipients see. At most 10.
	Cc []string
	// Bcc are bare addresses that get a copy the other recipients never see.
	// At most 10.
	Bcc []string
	// Attachments are files sent with the email: at most 10, and at most 40 MB
	// for the whole message after Base64 encoding, which leaves about 29 MB
	// for the files. Send checks both before any request. It then hashes each
	// file, uploads the files PostHog doesn't have yet straight to PostHog's
	// file storage, and sends the email naming them, so the network must
	// allow uploads to the storage host the upload URL names. A file PostHog
	// already has isn't uploaded again. PostHog refuses file types that
	// mailbox providers block, such as .exe. PostHog can't fetch a file from a
	// path or URL: read the file and pass its bytes. PostHog keeps each
	// uploaded file in its file storage for its retention period, and a later
	// send of the same bytes, from any of the project's code, reuses it.
	Attachments []EmailAttachment
	// Sensitive marks an email that carries a login link, a reset token or a
	// code. PostHog keeps a sensitive email's links unchanged, leaves its
	// subject off engagement events and keeps its content out of logs. Nil
	// takes the setting of the saved template whose key is TemplateKey, or
	// true when no template has that key.
	Sensitive *bool
	// Tracking says what PostHog tracks for this email. Nil keeps the
	// defaults: PostHog counts opens and captures engagement events, and
	// rewrites links to count clicks only when the email isn't Sensitive. Use
	// EmailTrackingOn, EmailTrackingOff or EmailTrackingWith.
	Tracking *EmailTracking
	// CaptureEngagement says whether PostHog captures the email's engagement
	// events as events of the recipient. Nil means true. A project whose
	// admin turned engagement capture off captures nothing, whatever the send
	// asks. PostHog refuses a send that sets both CaptureEngagement and
	// Tracking.
	//
	// Deprecated: Use Tracking with EmailTrackingOptions.Engagement.
	CaptureEngagement *bool
	// DistinctID is the recipient's distinct ID in your product. The email's
	// events go to this person. Without it, they go to a person whose distinct
	// ID is the email address.
	DistinctID string
	// IdempotencyKey is 1 to 255 visible ASCII characters. See
	// TemplateEmail.IdempotencyKey.
	IdempotencyKey string
	// MaxRetries overrides Config.EmailRequestMaxRetries for this send.
	// Ptr(0) turns retries off.
	MaxRetries *int
}
```

CodeEmail sends content your code rendered, named by a key. PostHog sends the subject and bodies as is and never stores them; it keeps attachments, as Attachments says. To send a React email, render it to HTML in your app and pass the HTML.

### `CommonResponseFields`

```go
type CommonResponseFields struct {
	// QuotaLimited lists quota-limited resources returned by the API.
	QuotaLimited []string `json:"quota_limited"`
	// RequestId is the API request identifier for tracing flag evaluation.
	RequestId string `json:"requestId"`
	// EvaluatedAt is the server evaluation timestamp, when returned.
	EvaluatedAt *int64 `json:"evaluatedAt"`
	// ErrorsWhileComputingFlags reports whether the server had errors computing any flags.
	ErrorsWhileComputingFlags bool `json:"errorsWhileComputingFlags"`
	// MinimalFlagCalledEvents reports whether the server enabled minimal
	// $feature_flag_called events for this project. The server sends it only
	// when the gate is on; absence means full events.
	MinimalFlagCalledEvents bool `json:"minimalFlagCalledEvents"`
}
```

CommonResponseFields contains fields common to all flags response versions.

### `CompressionMode`

```go
type CompressionMode uint8
```

CompressionMode specifies the compression algorithm for batch payloads.

```go
const (
	// CompressionNone disables compression (default).
	CompressionNone CompressionMode = 0
	// CompressionGzip enables GZIP compression for batch payloads. Valid on
	// both capture modes.
	CompressionGzip CompressionMode = 1
	// CompressionZstd enables Zstandard compression. Requires
	// CaptureModeAnalyticsV1 (the legacy /batch/ endpoint cannot decode it).
	CompressionZstd CompressionMode = 2
	// CompressionDeflate enables zlib (RFC 1950) compression, sent as
	// Content-Encoding: deflate. Requires CaptureModeAnalyticsV1.
	CompressionDeflate CompressionMode = 3
	// CompressionBrotli enables Brotli compression, sent as
	// Content-Encoding: br. Requires CaptureModeAnalyticsV1.
	CompressionBrotli CompressionMode = 4
)
```

#### `CompressionMode.String`

```go
func (m CompressionMode) String() string
```

String returns a human-readable codec name, used in config validation errors and debug logs. It is not the on-the-wire Content-Encoding token (brotli's token is "br"); see compressV1Body for wire tokens.

### `ConfigError`

```go
type ConfigError struct {
	// A human-readable message explaining why the configuration field's value
	// is invalid.
	Reason string

	// The name of the configuration field that was carrying an invalid value.
	Field string

	// The value of the configuration field that caused the error.
	Value interface{}
}
```

ConfigError is returned by NewWithConfig when a Config field has an invalid value.

#### `ConfigError.Error`

```go
func (e ConfigError) Error() string
```

Error returns a human-readable configuration error message.

### `DebugImage`

```go
type DebugImage struct {
	// Type is the image format: "elf" on Linux, "macho" on macOS.
	Type string `json:"type"`
	// DebugID identifies the uploaded symbol set for this image.
	DebugID string `json:"debug_id"`
	// CodeID is the full code identifier (the complete GNU build ID on ELF).
	CodeID string `json:"code_id,omitempty"`
	// ImageAddr is the runtime load address of the image, as hex.
	ImageAddr string `json:"image_addr"`
	// ImageSize is the loaded extent of the image in bytes.
	ImageSize uint64 `json:"image_size,omitempty"`
	// ImageVmaddr is the link-time base address of the image, as hex.
	ImageVmaddr string `json:"image_vmaddr,omitempty"`
	// CodeFile is the path of the binary on disk.
	CodeFile string `json:"code_file,omitempty"`
	// Arch is the processor architecture the image was built for.
	Arch string `json:"arch"`
}
```

DebugImage describes a binary image loaded into the process, sent as the event-level $debug\_images property so PostHog can symbolicate raw frame addresses against debug symbols uploaded with `posthog-cli symbol-sets upload`.

### `DebugImageProvider`

```go
type DebugImageProvider interface {
	GetDebugImages() []DebugImage
}
```

DebugImageProvider is implemented by stack trace extractors that can also report the binary images their frames reference. Integrations that accept a StackTraceExtractor (e.g. the slog capture handler) use it to attach $debug\_images to the exceptions they build.

### `DecideRequestData`

```go
type DecideRequestData struct {
	// ApiKey is the PostHog project API key.
	ApiKey string `json:"api_key"`
	// DistinctId is the user distinct ID to evaluate flags for.
	DistinctId string `json:"distinct_id"`
	// Groups contains group identifiers for group-targeted flags.
	Groups Groups `json:"groups"`
	// PersonProperties overrides person properties for this evaluation.
	PersonProperties Properties `json:"person_properties"`
	// GroupProperties overrides group properties for this evaluation, keyed by group type.
	GroupProperties map[string]Properties `json:"group_properties"`
}
```

DecideRequestData is the legacy wire-format request body for flag decide calls.

### `DecideResponse`

```go
type DecideResponse struct {
	// FeatureFlags contains evaluated flag values keyed by flag key.
	FeatureFlags map[string]interface{} `json:"featureFlags"`
	// FeatureFlagPayloads contains raw payloads keyed by flag key.
	FeatureFlagPayloads map[string]json.RawMessage `json:"featureFlagPayloads"`
}
```

DecideResponse is the legacy wire-format response body for flag decide calls.

### `DefaultStackTraceExtractor`

```go
type DefaultStackTraceExtractor struct {
	// InAppDecider decides whether each runtime frame is application code.
	// Set it to SimpleInAppDecider or another non-nil function before use.
	InAppDecider InAppDecider
}
```

DefaultStackTraceExtractor is provided by default as a sane / simple implementation of a StackTraceExtractor. It should be enough for most use cases, however, you're free to create your own implementation if you require more flexibility.

#### `DefaultStackTraceExtractor.GetDebugImages`

```go
func (d DefaultStackTraceExtractor) GetDebugImages() []DebugImage
```

GetDebugImages returns the debug images referenced by captured frames — currently the main executable, when its identity could be determined.

#### `DefaultStackTraceExtractor.GetStackTrace`

```go
func (d DefaultStackTraceExtractor) GetStackTrace(skip int) *ExceptionStacktrace
```

GetStackTrace captures the current goroutine stack in wire order (outermost frame first, capture site last). The skip parameter omits leading runtime.Callers frames before conversion.

When the running executable's identity is known (see DebugImage), frames are emitted as client-expanded inline groups for server-side symbolication: each physical stack frame and the entries the runtime synthesizes for calls inlined into it share one raw return address, with the synthesized layers tagged inline. PostHog resolves that address once against uploaded debug symbols and atomically replaces the whole group with its own expansion (exact inline chain, source context), or keeps these runtime-resolved frames verbatim when no symbols are uploaded. When the executable can't be identified, frames keep the plain pre-existing shape.

### `DescriptionExtractor`

```go
type DescriptionExtractor interface {
	// ExtractDescription returns the ExceptionItem.Value to use for a slog record.
	ExtractDescription(r slog.Record) string
}
```

DescriptionExtractor defines the interface for extracting a human-readable description from a slog.Record for use in exception capture.

Implementations should always return a non-empty string; returning an empty string will prevent the error from being captured.

### `Email`

```go
type Email interface {
	// contains filtered or unexported methods
}
```

Email is the content of one send: a TemplateEmail or a CodeEmail.

### `EmailAttachment`

```go
type EmailAttachment struct {
	// Filename is the name the recipient sees, such as "invoice.pdf", with no
	// path.
	Filename string
	// Content is the file's bytes.
	Content []byte
	// ContentType is a MIME type, such as "application/pdf". Without it, the
	// type follows from Filename.
	ContentType string
	// ContentID shows the file inline: the HTML references it as
	// <img src="cid:logo"> when ContentID is "logo".
	ContentID string
}
```

EmailAttachment is a file sent with a CodeEmail.

### `EmailError`

```go
type EmailError struct {
	Name    EmailErrorName
	Code    string
	Message string
	// StatusCode is the HTTP status when PostHog, or file storage for an
	// upload, answered, and 0 otherwise.
	// A network_error keeps the status of an answer that broke off mid-body.
	StatusCode int
	Why        string
	Fix        string
	DocsURL    string
	// Field names the request field the error is about, when there is one.
	Field string
	// RetryAfter is how long PostHog, or file storage for an upload, asked the
	// client to wait before it tries again, and 0 when it did not ask.
	RetryAfter time.Duration
}
```

EmailError reports that PostHog did not queue the email or return its status, or that the client could not tell whether it did. Every error that Emails returns is an \*EmailError; read it with errors.As.

Branch on Code, PostHog's stable error code such as "recipient\_suppressed", or an SDK code such as "network\_error" or "missing\_app\_host". Name is its coarse category. The error never holds the secret key or the request body.

#### `EmailError.Error`

```go
func (e *EmailError) Error() string
```

#### `EmailError.Unwrap`

```go
func (e *EmailError) Unwrap() error
```

Unwrap returns the cause, such as a network error, context.DeadlineExceeded, ErrSDKDisabled or ErrClosed.

### `EmailErrorName`

```go
type EmailErrorName string
```

EmailErrorName is a coarse category of an EmailError, for code that branches on the kind of failure rather than the exact code. The names follow Resend's error names, so code moved from Resend keeps working.

```go
const (
	// EmailErrorValidation: PostHog or the client refused the email as sent,
	// such as an unverified sender, a suppressed recipient or an argument the
	// client checks before any request.
	EmailErrorValidation EmailErrorName = "validation_error"
	// EmailErrorMissingAPIKey: the client has no secret key, or PostHog
	// refused it.
	EmailErrorMissingAPIKey EmailErrorName = "missing_api_key"
	// EmailErrorInvalidPermission: the secret key lacks the scope.
	EmailErrorInvalidPermission EmailErrorName = "invalid_permission"
	// EmailErrorNotFound: no template or email with this ID, or the API is not
	// enabled for the project. On Attachments it can also mean this PostHog
	// can't take attachments yet; the client can't tell which.
	EmailErrorNotFound EmailErrorName = "not_found"
	// EmailErrorConcurrentIdempotentRequests: a send with the same idempotency
	// key is still in flight.
	EmailErrorConcurrentIdempotentRequests EmailErrorName = "concurrent_idempotent_requests"
	// EmailErrorInvalidIdempotentRequest: the idempotency key was used with
	// another request.
	EmailErrorInvalidIdempotentRequest EmailErrorName = "invalid_idempotent_request"
	// EmailErrorRateLimitExceeded: PostHog, or file storage for an upload,
	// rate limited the request.
	EmailErrorRateLimitExceeded EmailErrorName = "rate_limit_exceeded"
	// EmailErrorMonthlyQuotaExceeded: the project is over its email quota.
	EmailErrorMonthlyQuotaExceeded EmailErrorName = "monthly_quota_exceeded"
	// EmailErrorDailyQuotaExceeded: the project uploaded as many attachment
	// bytes as it can today, counted in UTC. Files PostHog already has don't
	// count, and emails without new attachments still go out.
	EmailErrorDailyQuotaExceeded EmailErrorName = "daily_quota_exceeded"
	// EmailErrorServiceUnavailable: PostHog, file storage for an upload, or
	// the network was unavailable.
	EmailErrorServiceUnavailable EmailErrorName = "service_unavailable"
	// EmailErrorApplication: anything else.
	EmailErrorApplication EmailErrorName = "application_error"
)
```

### `EmailStatus`

```go
type EmailStatus struct {
	// ID is the message ID that Send returned.
	ID string
	// Status is "queued", "sent", "failed", "delivered", "bounced" or
	// "complained" today. Later SDK versions can see values this list does not
	// have yet.
	Status string
	// CreatedAt is when PostHog queued the email.
	CreatedAt time.Time
	// StatusAt is when the email reached its current status.
	StatusAt time.Time
	// Reason says why a failed email was not sent, such as "provider_error" or
	// "recipient_suppressed", or gives the bounce type of a bounced email:
	// "hard", "soft" or "unknown". It is empty otherwise.
	Reason string
}
```

EmailStatus is what happened to an email that Emails.Send queued.

### `EmailTracking`

```go
type EmailTracking struct {
	// contains filtered or unexported fields
}
```

EmailTracking says what PostHog tracks for a CodeEmail. Make one with EmailTrackingOn, EmailTrackingOff or EmailTrackingWith.

#### `EmailTracking.MarshalJSON`

```go
func (t EmailTracking) MarshalJSON() ([]byte, error)
```

MarshalJSON encodes the tracking as true, false or an object of the kinds that are set.

#### `posthog.EmailTrackingOff`

```go
func EmailTrackingOff() *EmailTracking
```

EmailTrackingOff turns off every kind of tracking, including kinds PostHog adds later. PostHog then can't count the email's opens and clicks, and captures no engagement events.

#### `posthog.EmailTrackingOn`

```go
func EmailTrackingOn() *EmailTracking
```

EmailTrackingOn tracks opens and clicks and captures engagement events. Use it only when the email's links are safe to send through a redirect.

#### `posthog.EmailTrackingWith`

```go
func EmailTrackingWith(options EmailTrackingOptions) *EmailTracking
```

EmailTrackingWith sets each kind of tracking on its own.

### `EmailTrackingOptions`

```go
type EmailTrackingOptions struct {
	// Opens says whether PostHog adds its open pixel to count opens. Nil
	// means true. With Opens false, PostHog counts no clicks, and refuses
	// Clicks true.
	Opens *bool `json:"opens,omitempty"`
	// Clicks says whether PostHog rewrites the email's links to count clicks.
	// Nil means true when the email isn't Sensitive and false when it is.
	// Turn it on only when the links are safe to send through a redirect, so
	// not for a login or password reset link. A link with a data-ph-no-track
	// attribute is never rewritten.
	Clicks *bool `json:"clicks,omitempty"`
	// Engagement says whether PostHog captures the email's engagement events,
	// such as opens and clicks, as events of the recipient. Nil means true.
	Engagement *bool `json:"engagement,omitempty"`
}
```

EmailTrackingOptions turns each kind of tracking on or off. A nil field keeps its default.

### `EmailWarning`

```go
type EmailWarning struct {
	Code    string
	Message string
	Fix     string
}
```

EmailWarning is a warning PostHog returned with a queued email.

### `Emails`

```go
type Emails interface {
	// Send queues one email, from a TemplateEmail made in PostHog or from a
	// CodeEmail your code rendered. A result means PostHog queued the email,
	// not that it was delivered.
	Send(ctx context.Context, email Email) (*SendEmailResult, error)

	// Get reads the status of an email that Send queued, for 30 days after the
	// send. The error code is "not_found" when no email of the project has the
	// ID, when the email is older than 30 days, or for a few seconds after the
	// send.
	Get(ctx context.Context, messageID string) (*EmailStatus, error)
}
```

Emails sends transactional email, such as a password reset or a receipt, to one recipient per call, and reads the status of an email it sent.

It needs Config.SecretKey, a project secret API key (phs\_...) with the transactional\_email:write scope, the "Send transactional email" preset in your project settings. A key with only transactional\_email:read can read statuses but not send. Keys made with hog\_flow:write still work. Requests go to Config.AppHost, or to the PostHog Cloud app host of Config.Endpoint.

Every error is an \*EmailError. Network errors, rate limits, an idempotency key in flight and an unavailable service are retried up to Config.EmailRequestMaxRetries times, with the same idempotency key.

### `EnqueueClient`

```go
type EnqueueClient interface {
	// Enqueue queues a message to be sent by the client when the conditions for a batch
	// upload are met.
	// This is the main method you'll be using, a typical flow would look like
	// this:
	//
	//	client := posthog.New(apiKey)
	//	...
	//	client.Enqueue(posthog.Capture{ ... })
	//	...
	//	client.Close()
	//
	// Enqueue returns an error if the message could not be queued, which happens
	// when the client is closed, the message is invalid, or the in-memory queue
	// is full (ErrQueueFull) -- in the latter case the message is dropped rather
	// than blocking the caller. A full-queue drop is reported only through this
	// returned error, not through Callback.Failure.
	//
	// Bulk or backfill workloads that can enqueue faster than the client uploads
	// should check the returned error for ErrQueueFull and throttle or retry (or
	// raise Config.MaxQueueSize); otherwise events are dropped, not delayed.
	Enqueue(Message) error
}
```

EnqueueClient is the minimal interface implemented by clients that can queue PostHog messages.

### `ErrorExtractor`

```go
type ErrorExtractor struct {
	// ErrorKeys are attribute keys to inspect for error values, case-insensitively.
	ErrorKeys []string
	// Fallback is returned when no matching error attribute is found.
	Fallback string
}
```

ErrorExtractor implements DescriptionExtractor by scanning a slog.Record for attributes containing an error.

ErrorKeys specifies the list of attribute keys (case-insensitive) to check. The first matching attribute with an error value is returned as the description. If no matching error is found, the Fallback is returned.

#### `ErrorExtractor.ExtractDescription`

```go
func (e ErrorExtractor) ExtractDescription(r slog.Record) string
```

ExtractDescription returns the first matching error string from the slog record or Fallback.

### `ExceptionInApi`

```go
type ExceptionInApi struct {
	// Type is the legacy message type sent to the batch API.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string `json:"type"`
	// Uuid is the valid event UUID sent to the batch API.
	Uuid string `json:"uuid"`
	// Library is the SDK name sent to the batch API.
	Library string `json:"library"`
	// LibraryVersion is the SDK version sent to the batch API.
	LibraryVersion string `json:"library_version"`
	// Timestamp is the event timestamp sent to the batch API in UTC.
	Timestamp time.Time `json:"timestamp"`
	// Event is always $exception for Exception messages.
	Event string `json:"event"`
	// Properties contains built-in and custom exception properties.
	Properties ExceptionInApiProperties `json:"properties"`
}
```

ExceptionInApi is the wire-format payload produced from an Exception message.

### `ExceptionInApiProperties`

```go
type ExceptionInApiProperties struct {
	// Lib is the SDK name sent as $lib.
	Lib string `json:"$lib"`
	// LibVersion is the SDK version sent as $lib_version.
	LibVersion string `json:"$lib_version"`
	// IsServer marks the event as originating from a server-side SDK.
	// Omitted entirely when nil (Config.IsServer resolved to false).
	IsServer *bool `json:"$is_server,omitempty"`
	// DistinctId is the user distinct ID associated with the exception.
	DistinctId string `json:"distinct_id"`
	// DisableGeoIP is sent as $geoip_disable when GeoIP lookup is disabled.
	DisableGeoIP bool `json:"$geoip_disable,omitempty"`
	// DebugImages is sent as $debug_images when "native" frames are present.
	DebugImages []DebugImage `json:"$debug_images,omitempty"`
	// ExceptionList is sent as $exception_list.
	ExceptionList []ExceptionItem `json:"$exception_list"`
	// ExceptionFingerprint is sent as $exception_fingerprint when provided.
	ExceptionFingerprint *string `json:"$exception_fingerprint,omitempty"`

	// Custom is flattened into the wire "properties" on marshal.
	// Typed fields win on collision.
	Custom Properties `json:"-"`
}
```

ExceptionInApiProperties is the wire-format properties object for an Exception message.

#### `ExceptionInApiProperties.MarshalJSON`

```go
func (p ExceptionInApiProperties) MarshalJSON() ([]byte, error)
```

MarshalJSON lets users add extra keys (via Custom) to the event's JSON output next to the built-in ones like $lib and distinct\_id. If a custom key clashes with a built-in, we keep ours and drop theirs.

#### `ExceptionInApiProperties.ToProperties`

```go
func (ctx ExceptionInApiProperties) ToProperties() Properties
```

### `ExceptionItem`

```go
type ExceptionItem struct {
	// Type is rendered as the exception title in the PostHog UI.
	Type string `json:"type"`
	// Value is rendered as the exception description in the PostHog UI.
	Value string `json:"value"`
	// Mechanism describes how the exception was produced or handled.
	Mechanism *ExceptionMechanism `json:"mechanism,omitempty"`
	// Stacktrace contains stack frames for the exception. Use StackTraceExtractor to generate it.
	Stacktrace *ExceptionStacktrace `json:"stacktrace,omitempty"`
}
```

ExceptionItem describes one exception in an Exception event.

#### `ExceptionItem.Validate`

```go
func (msg ExceptionItem) Validate() error
```

Validate checks that the exception item has Type and Value set.

### `ExceptionMechanism`

```go
type ExceptionMechanism struct {
	// Handled reports whether the exception was handled by application code.
	Handled *bool `json:"handled,omitempty"`
	// Synthetic reports whether the exception was synthesized by instrumentation.
	Synthetic *bool `json:"synthetic,omitempty"`
}
```

ExceptionMechanism describes whether an exception was handled or synthesized.

### `ExceptionStacktrace`

```go
type ExceptionStacktrace struct {
	// Type is the stack trace representation type. The default extractor uses "raw".
	Type string `json:"type"`
	// Frames is the ordered list of stack frames.
	Frames []StackFrame `json:"frames"`
}
```

ExceptionStacktrace is a PostHog-compatible stack trace.

### `FeatureFlag`

```go
type FeatureFlag struct {
	// Key is the feature flag key.
	Key string `json:"key"`
	// EvaluationRuntime is the flag's configured runtime, or nil when unknown.
	EvaluationRuntime *string `json:"evaluation_runtime"`
	// RolloutPercentage is the top-level rollout percentage, when configured.
	RolloutPercentage *float64 `json:"rollout_percentage"`
	// Active reports whether the flag is active.
	Active bool `json:"active"`
	// Filters contains matching conditions, variants, and payloads.
	Filters Filter `json:"filters"`
	// EnsureExperienceContinuity indicates that the flag requires server-side continuity checks.
	EnsureExperienceContinuity *bool `json:"ensure_experience_continuity"`
	// BucketingIdentifier optionally selects the property used for hash bucketing.
	BucketingIdentifier *string `json:"bucketing_identifier"`
	// HasExperiment reports whether the flag is linked to an experiment.
	// Nil when the server does not send it (older deployments).
	HasExperiment *bool `json:"has_experiment"`
}
```

FeatureFlag is a feature flag definition returned by the local evaluation endpoint.

### `FeatureFlagCondition`

```go
type FeatureFlagCondition struct {
	// Properties are the targeting rules in this condition group.
	Properties []FlagProperty `json:"properties"`
	// RolloutPercentage is the rollout percentage for this condition group.
	RolloutPercentage *float64 `json:"rollout_percentage"`
	// Variant is the variant key forced by this condition group, when any.
	Variant *string `json:"variant"`
	// AggregationGroupTypeIndex identifies the group type for this condition group.
	AggregationGroupTypeIndex *uint8 `json:"aggregation_group_type_index"`
}
```

FeatureFlagCondition describes one condition group for a feature flag.

### `FeatureFlagPayload`

```go
type FeatureFlagPayload struct {
	// Key is the feature flag key to evaluate. It is required.
	Key string
	// DistinctId is the user distinct ID to evaluate the flag for. It is required.
	DistinctId string
	// DeviceId optionally provides a device_id for remote /flags requests and event deduplication.
	DeviceId *string
	// Groups supplies group identifiers for group-targeted flags.
	Groups Groups
	// PersonProperties overrides person properties used during flag evaluation.
	PersonProperties Properties
	// GroupProperties overrides group properties used during flag evaluation, keyed by group type.
	GroupProperties map[string]Properties
	// OnlyEvaluateLocally prevents fallback to remote /flags requests.
	OnlyEvaluateLocally bool
	// SendFeatureFlagEvents controls whether $feature_flag_called is captured.
	// Nil defaults to true during validation.
	SendFeatureFlagEvents *bool
}
```

FeatureFlagPayload configures a single legacy feature flag evaluation. It is used by Client.GetFeatureFlag, Client.IsFeatureEnabled, Client.GetFeatureFlagResult, and Client.GetFeatureFlagPayload.

### `FeatureFlagPayloadNoKey`

```go
type FeatureFlagPayloadNoKey struct {
	// DistinctId is the user distinct ID to evaluate flags for. It is required.
	DistinctId string
	// DeviceId optionally provides a device_id for remote /flags requests and event deduplication.
	DeviceId *string
	// Groups supplies group identifiers for group-targeted flags.
	Groups Groups
	// PersonProperties overrides person properties used during flag evaluation.
	PersonProperties Properties
	// GroupProperties overrides group properties used during flag evaluation, keyed by group type.
	GroupProperties map[string]Properties
	// OnlyEvaluateLocally prevents fallback to remote /flags requests.
	OnlyEvaluateLocally bool
	// SendFeatureFlagEvents is reserved for parity with single-flag payloads.
	// Nil defaults to true during validation; GetAllFlags does not currently emit per-flag access events.
	SendFeatureFlagEvents *bool
}
```

FeatureFlagPayloadNoKey configures legacy evaluation of all flags for one user. It is used by Client.GetAllFlags.

### `FeatureFlagResult`

```go
type FeatureFlagResult struct {
	// Key is the feature flag key that was evaluated
	Key string

	// Enabled indicates whether the feature flag evaluation determined
	// the flag to be in an enabled state.
	Enabled bool

	// RawPayload is the serialized JSON payload associated with the flag variant.
	// Nil if no payload is configured.
	// Use GetPayloadAs to unmarshal the payload into a specific type.
	RawPayload *string

	// Variant is the variant key if this is a multivariate flag.
	// Nil for boolean flags.
	Variant *string
}
```

FeatureFlagResult represents the result of a feature flag evaluation, containing both the flag value and its payload.

#### `FeatureFlagResult.GetPayloadAs`

```go
func (r *FeatureFlagResult) GetPayloadAs(v interface{}) error
```

GetPayloadAs unmarshals the JSON payload into the provided type. Returns an error if the payload is empty or cannot be unmarshaled.

### `FeatureFlagsPoller`

```go
type FeatureFlagsPoller struct {
	// Logger receives poller warnings and errors.
	Logger Logger
	// Endpoint is the PostHog API host used by the poller.
	Endpoint string
}
```

FeatureFlagsPoller periodically loads feature flag definitions for local evaluation. Applications normally interact with it through Client methods rather than constructing it directly.

#### `FeatureFlagsPoller.ForceReload`

```go
func (poller *FeatureFlagsPoller) ForceReload()
```

ForceReload requests an immediate reload of local feature flag definitions. It does nothing once the poller has shut down. The send selects on shutdown so a reload racing Close cannot send on a closed channel.

#### `FeatureFlagsPoller.GetAllFlags`

```go
func (poller *FeatureFlagsPoller) GetAllFlags(flagConfig FeatureFlagPayloadNoKey) (map[string]interface{}, error)
```

GetAllFlags evaluates every available flag for the configured user. Values are bools for boolean flags or strings for multivariate variants.

#### `FeatureFlagsPoller.GetFeatureFlag`

```go
func (poller *FeatureFlagsPoller) GetFeatureFlag(flagConfig FeatureFlagPayload) (interface{}, bool, error)
```

GetFeatureFlag evaluates one flag using locally loaded definitions when possible. It returns the flag value, whether that value was locally evaluated, and an error. If local evaluation is inconclusive and OnlyEvaluateLocally is false, it falls back to /flags.

#### `FeatureFlagsPoller.GetFeatureFlagPayload`

```go
func (poller *FeatureFlagsPoller) GetFeatureFlagPayload(flagConfig FeatureFlagPayload) (string, error)
```

GetFeatureFlagPayload returns the payload for the evaluated flag value. It tries local payloads first and falls back to the remote API unless OnlyEvaluateLocally is true.

#### `FeatureFlagsPoller.GetFeatureFlagWithPayload`

```go
func (poller *FeatureFlagsPoller) GetFeatureFlagWithPayload(flagConfig FeatureFlagPayload) flagValueAndPayload
```

GetFeatureFlagWithPayload evaluates a feature flag once and returns both its value and payload. This avoids the double evaluation that would happen when calling GetFeatureFlag and GetFeatureFlagPayload separately.

#### `FeatureFlagsPoller.GetFeatureFlags`

```go
func (poller *FeatureFlagsPoller) GetFeatureFlags() ([]FeatureFlag, error)
```

GetFeatureFlags returns the locally loaded feature flag definitions. It waits for the initial poll to complete and returns an error if flags were not loaded.

### `FeatureFlagsResponse`

```go
type FeatureFlagsResponse struct {
	// Flags contains feature flag definitions for local evaluation.
	Flags []FeatureFlag `json:"flags"`
	// GroupTypeMapping maps group type indexes to group type names.
	GroupTypeMapping *map[string]string `json:"group_type_mapping"`
	// Cohorts contains cohort definitions referenced by local feature flags.
	Cohorts map[string]PropertyGroup `json:"cohorts"`
	// MinimalFlagCalledEvents reports whether the server enabled minimal
	// $feature_flag_called events for this project. The server sends it only
	// when the gate is on; absence means full events.
	MinimalFlagCalledEvents bool `json:"minimal_flag_called_events"`
}
```

FeatureFlagsResponse is the wire-format response from the local evaluation endpoint.

### `FieldError`

```go
type FieldError struct {
	// The human-readable representation of the type of structure that wasn't
	// initialized properly.
	Type string

	// The name of the field that wasn't properly initialized.
	Name string

	// The value of the field that wasn't properly initialized.
	Value interface{}
}
```

FieldError describes an invalid required field in a message passed to the SDK.

#### `FieldError.Error`

```go
func (e FieldError) Error() string
```

Error returns a human-readable field validation error message.

### `Filter`

```go
type Filter struct {
	// AggregationGroupTypeIndex identifies the group type for group-targeted flags.
	AggregationGroupTypeIndex *uint8 `json:"aggregation_group_type_index"`
	// Groups contains the ordered condition groups to evaluate.
	Groups []FeatureFlagCondition `json:"groups"`
	// EarlyExit, when true, stops local condition evaluation and returns a
	// definitive disabled result as soon as a condition group matches its
	// property filters (or has none) but the rollout percentage excludes the
	// user, instead of falling through to later condition groups.
	EarlyExit bool `json:"early_exit"`
	// Multivariate contains variant definitions for multivariate flags.
	Multivariate *Variants `json:"multivariate"`
	// Holdout contains the experiment holdout configuration, when the flag has one.
	Holdout *Holdout `json:"holdout"`
	// Payloads maps flag values or variant keys to raw JSON payloads.
	Payloads map[string]json.RawMessage `json:"payloads"`
	// DecodedPayloads holds pre-decoded string versions of Payloads.
	// Built once at flag load time to avoid per-evaluation json.Unmarshal / unquoting.
	DecodedPayloads map[string]string `json:"-"`
	// VariantLookupTable is pre-computed at flag load time to avoid per-evaluation
	// slice allocation for multivariate flags.
	VariantLookupTable []FlagVariantMeta `json:"-"`
}
```

Filter contains the targeting rules, variants, and payloads for a FeatureFlag.

### `FlagDefinitionCacheProvider`

```go
type FlagDefinitionCacheProvider interface {
	// GetFlagDefinitions returns the cached JSON, or nil when nothing is cached.
	GetFlagDefinitions(ctx context.Context) (json.RawMessage, error)

	// ShouldFetchFlagDefinitions reports whether this instance should fetch
	// definitions from PostHog on this poll. Only instances with a SecretKey call
	// this method, so cache-only readers cannot acquire a fetch lease.
	ShouldFetchFlagDefinitions(ctx context.Context) (bool, error)

	// OnFlagDefinitionsReceived stores the JSON fetched from PostHog unchanged.
	OnFlagDefinitionsReceived(ctx context.Context, data json.RawMessage) error

	// Shutdown releases any resources held by the provider, such as a lock
	// acquired by ShouldFetchFlagDefinitions. It runs after active provider calls
	// finish. If client shutdown times out, cleanup may complete after Close or
	// CloseWithContext returns.
	Shutdown(ctx context.Context) error
}
```

FlagDefinitionCacheProvider shares feature flag definitions between SDK instances through an external cache such as Redis. Definition data is opaque: providers store and return it unchanged; the SDK validates and interprets it. Without a SecretKey, SDK instances only read the cache and never consult the fetch decision or publish definitions. Instances with a SecretKey consult the fetch decision and publish definitions after an elected fetch. Implementations should honor context cancellation so polling and resource cleanup can finish promptly.

EXPERIMENTAL: this interface may change in a minor version bump.

### `FlagDetail`

```go
type FlagDetail struct {
	// Key is the feature flag key.
	Key string `json:"key"`
	// Enabled reports whether the flag is enabled for the evaluated user.
	Enabled bool `json:"enabled"`
	// Variant is the matched variant key for multivariate flags, or nil for boolean flags.
	Variant *string `json:"variant"`
	// Reason explains why the flag matched or did not match, when provided by the API.
	Reason *FlagReason `json:"reason"`
	// Metadata contains IDs, version, payload, and optional flag description.
	Metadata FlagMetadata `json:"metadata"`
	// Failed is true when the API could not evaluate this flag due to a transient failure.
	Failed *bool `json:"failed,omitempty"`
}
```

FlagDetail represents one evaluated feature flag in the v4 /flags response format.

#### `FlagDetail.GetValue`

```go
func (f FlagDetail) GetValue() interface{}
```

GetValue returns the variant string when Variant is set; otherwise it returns Enabled.

#### `posthog.NewFlagDetail`

```go
func NewFlagDetail(key string, value interface{}, payload json.RawMessage) FlagDetail
```

NewFlagDetail creates a FlagDetail from a flag key, a bool or string value, and an optional raw JSON payload. String values are treated as enabled variants; bool values are treated as boolean flag results.

### `FlagMetadata`

```go
type FlagMetadata struct {
	// ID is the numeric feature flag ID in PostHog.
	ID int `json:"id"`
	// Version is the feature flag version evaluated by the API.
	Version int `json:"version"`
	// Payload is the raw JSON payload associated with the matched flag value.
	Payload json.RawMessage `json:"payload"`
	// Description is the feature flag description, when returned by the API.
	Description *string `json:"description,omitempty"`
	// HasExperiment reports whether the flag is linked to an experiment.
	// Nil when the server does not send it (older deployments).
	HasExperiment *bool `json:"has_experiment"`
}
```

FlagMetadata contains additional information about a flag evaluation.

### `FlagProperty`

```go
type FlagProperty struct {
	// Key is the property key to read.
	Key string `json:"key"`
	// Operator is the comparison operator, such as exact, is_not, or regex.
	Operator string `json:"operator"`
	// Value is the comparison value for Operator.
	Value interface{} `json:"value"`
	// Type is the property source. Supported values include "person", "group", "cohort", and "flag".
	Type string `json:"type"`
	// Negation inverts the property match when true.
	Negation bool `json:"negation"`
	// DependencyChain tracks feature flag dependencies while evaluating nested flag properties.
	DependencyChain []string `json:"dependency_chain"`
}
```

FlagProperty describes one property matcher in a feature flag or cohort condition.

### `FlagReason`

```go
type FlagReason struct {
	// Code is the machine-readable reason code returned by the API.
	Code string `json:"code"`
	// Description is the human-readable reason returned by the API.
	Description string `json:"description"`
	// ConditionIndex is the matched condition index, when available.
	ConditionIndex *int `json:"condition_index"`
}
```

FlagReason represents why a flag was enabled or disabled.

### `FlagVariant`

```go
type FlagVariant struct {
	// Key is the stable variant key returned by flag evaluation.
	Key string `json:"key"`
	// Name is the display name for the variant.
	Name string `json:"name"`
	// RolloutPercentage is the percentage allocated to this variant.
	RolloutPercentage *float64 `json:"rollout_percentage"`
}
```

FlagVariant describes one multivariate feature flag variant.

### `FlagVariantMeta`

```go
type FlagVariantMeta struct {
	// ValueMin is the inclusive lower bound of the normalized hash range.
	ValueMin float64
	// ValueMax is the exclusive upper bound of the normalized hash range.
	ValueMax float64
	// Key is the variant key for this hash range.
	Key string
}
```

FlagVariantMeta is a precomputed hash range for a feature flag variant.

### `FlagsRequestData`

```go
type FlagsRequestData struct {
	// ApiKey is the PostHog project API key.
	ApiKey string `json:"api_key"`
	// DistinctId is the user distinct ID to evaluate flags for.
	DistinctId string `json:"distinct_id"`
	// DeviceId optionally identifies the device for device-aware flag evaluation.
	DeviceId *string `json:"device_id,omitempty"`
	// Groups contains group identifiers for group-targeted flags.
	Groups Groups `json:"groups"`
	// PersonProperties overrides person properties for this evaluation.
	PersonProperties Properties `json:"person_properties"`
	// GroupProperties overrides group properties for this evaluation, keyed by group type.
	GroupProperties map[string]Properties `json:"group_properties"`
	// DisableGeoIP disables GeoIP enrichment for this flags request.
	DisableGeoIP bool `json:"geoip_disable,omitempty"`
	// FlagKeysToEvaluate asks the server to evaluate only these flag keys when non-empty.
	FlagKeysToEvaluate []string `json:"flag_keys_to_evaluate,omitempty"`
}
```

FlagsRequestData is the wire-format request body sent to the /flags endpoint.

### `FlagsResponse`

```go
type FlagsResponse struct {
	// CommonResponseFields contains response metadata shared across formats.
	CommonResponseFields

	// Flags contains v4-format flag details keyed by flag key.
	Flags map[string]FlagDetail `json:"flags,omitempty"`

	// FeatureFlags contains legacy v3 flag values keyed by flag key.
	FeatureFlags map[string]interface{} `json:"featureFlags"`
	// FeatureFlagPayloads contains legacy v3 raw payloads keyed by flag key.
	FeatureFlagPayloads map[string]json.RawMessage `json:"featureFlagPayloads"`
}
```

FlagsResponse represents a normalized /flags response. It accepts both legacy v3 and current v4 response shapes.

#### `FlagsResponse.UnmarshalJSON`

```go
func (r *FlagsResponse) UnmarshalJSON(data []byte) error
```

UnmarshalJSON implements custom unmarshaling to handle both v3 and v4 formats

### `GroupIdentifyInApi`

```go
type GroupIdentifyInApi struct {
	// Uuid is the valid event UUID sent to the batch API.
	Uuid string `json:"uuid"`
	// Library is the SDK name sent to the batch API.
	Library string `json:"library"`
	// LibraryVersion is the SDK version sent to the batch API.
	LibraryVersion string `json:"library_version"`
	// Timestamp is the event timestamp sent to the batch API in UTC.
	Timestamp time.Time `json:"timestamp"`

	// Event is always $groupidentify for GroupIdentify messages.
	Event string `json:"event"`
	// DistinctId is the generated group distinct ID sent to PostHog.
	DistinctId string `json:"distinct_id"`
	// Properties contains SDK metadata, group identifiers, and $group_set properties.
	Properties Properties `json:"properties"`
}
```

GroupIdentifyInApi is the wire-format payload produced from a GroupIdentify message.

### `Groups`

```go
type Groups map[string]interface{}
```

Groups is used to represent groups in messages that support it. It is a free-form object so the application can set any value it sees fit but a few helper methods are defined to make it easier to instantiate groups with common fields.

#### `Groups.Set`

```go
func (p Groups) Set(name string, value interface{}) Groups
```

Set assigns a group type to a group key or ID and returns the receiver.

#### `posthog.NewGroups`

```go
func NewGroups() Groups
```

NewGroups creates an empty Groups map for fluent construction.

### `Holdout`

```go
type Holdout struct {
	// ID identifies the holdout. It is rendered into the synthetic variant key.
	ID interface{} `json:"id"`
	// ExclusionPercentage is the share of identifiers held out, from 0 to 100.
	ExclusionPercentage *float64 `json:"exclusion_percentage"`
}
```

Holdout is the experiment holdout configuration attached to a feature flag. Identifiers inside the holdout are excluded from the flag's release conditions and resolve to the synthetic variant "holdout-<id>".

### `IdentifyInApi`

```go
type IdentifyInApi struct {
	// Type is the legacy message type sent to the batch API.
	// Deprecated: this field is ignored by PostHog ingestion and is kept for backwards compatibility.
	Type string `json:"type"`
	// Uuid is the valid event UUID sent to the batch API.
	Uuid string `json:"uuid"`
	// Library is the SDK name sent to the batch API.
	Library string `json:"library"`
	// LibraryVersion is the SDK version sent to the batch API.
	LibraryVersion string `json:"library_version"`
	// Timestamp is the event timestamp sent to the batch API in UTC.
	Timestamp time.Time `json:"timestamp"`

	// Event is always $identify for Identify messages.
	Event string `json:"event"`
	// DistinctId is the user distinct ID sent to PostHog.
	DistinctId string `json:"distinct_id"`
	// Properties contains SDK metadata and system context.
	Properties Properties `json:"properties"`
	// Set contains the person properties to update.
	Set Properties `json:"$set"`
}
```

IdentifyInApi is the wire-format payload produced from an Identify message.

### `InAppDecider`

```go
type InAppDecider func(frame runtime.Frame) bool
```

InAppDecider reports whether a stack frame should be considered “in-app” (i.e., part of the calling application’s own code) as opposed to external dependencies, standard library, or tooling internals. The UI can use this signal to visually emphasize frames that are likely actionable.

### `InconclusiveMatchError`

```go
type InconclusiveMatchError struct {
	// Reason is why local evaluation could not resolve the flag.
	Reason UnresolvedFlagReason
}
```

InconclusiveMatchError indicates that local evaluation could not conclusively match a condition.

#### `InconclusiveMatchError.Error`

```go
func (e *InconclusiveMatchError) Error() string
```

Error returns the inconclusive match message.

### `Logger`

```go
type Logger interface {
	// Debugf is called by PostHog client to log debug messages about the
	// operations they perform. Messages logged by this method are usually
	// tagged with an `DEBUG` log level in common logging libraries.
	Debugf(format string, args ...interface{})

	// Logf is called by PostHog client to log regular messages about the
	// operations they perform. Messages logged by this method are usually
	// tagged with an `INFO` log level in common logging libraries.
	Logf(format string, args ...interface{})

	// Warnf is called by PostHog client to log warning messages about
	// the operations they perform. Messages logged by this method are usually
	// tagged with an `WARN` log level in common logging libraries.
	Warnf(format string, args ...interface{})

	// Errorf is called by PostHog clients call this method to log errors
	// they encounter while sending events to the backend servers.
	// Messages logged by this method are usually tagged with an `ERROR` log
	// level in common logging libraries.
	Errorf(format string, args ...interface{})
}
```

Logger defines the logging interface used by PostHog clients.

#### `posthog.StdLogger`

```go
func StdLogger(logger *log.Logger, verbose bool) Logger
```

StdLogger wraps a standard log.Logger as a PostHog Logger. The verbose parameter controls whether Debugf messages are emitted.

### `Message`

```go
type Message interface {
	// Validate checks the internal structure of the message. It returns nil when
	// the message is valid or an error describing the invalid field.
	Validate() error
	// APIfy converts the message into its PostHog batch API representation.
	APIfy() APIMessage
}
```

Message represents a PostHog object that can be queued with Client.Enqueue.

Built-in message types such as Capture, Identify, Alias, GroupIdentify, and Exception implement this interface. The unexported internal method prevents external packages from defining arbitrary message implementations.

### `Properties`

```go
type Properties map[string]interface{}
```

Properties is used to represent properties in messages that support it. It is a free-form object so the application can set any value it sees fit but a few helper method are defined to make it easier to instantiate properties with common fields. Here's a quick example of how this type is meant to be used:

```go
posthog.Capture{
	DistinctId: "0123456789",
	Event:      "order completed",
	Properties: posthog.NewProperties().
		Set("revenue", 10.0).
		Set("currency", "USD"),
}
```

#### `Properties.Merge`

```go
func (p Properties) Merge(props Properties) Properties
```

Merge adds the properties from the provided `props` into the receiver `p`. If a property in `props` already exists in `p`, its value will be overwritten.

#### `Properties.Set`

```go
func (p Properties) Set(name string, value interface{}) Properties
```

Set assigns a property value and returns the receiver.

#### `posthog.NewProperties`

```go
func NewProperties() Properties
```

NewProperties creates an empty Properties map for fluent construction.

#### `posthog.SlogAttrsAsProperties`

```go
func SlogAttrsAsProperties(_ context.Context, r slog.Record) Properties
```

SlogAttrsAsProperties is a convenience implementation of the fn passed to WithPropertiesFn. It copies every slog.Record attribute into a Properties map, so log fields flow onto the captured exception event verbatim.

Usage: posthog.WithPropertiesFn(posthog.SlogAttrsAsProperties)

Note: this ships all attrs to PostHog — make sure none contain sensitive data, or write a filtering fn instead.

### `PropertyGroup`

```go
type PropertyGroup struct {
	// Type is the boolean operator joining Values, such as AND or OR.
	Type string `json:"type"`
	// Values contains nested PropertyGroup values or FlagProperty values.
	Values []any `json:"values"`
	// ParsedValues holds pre-parsed typed values from Values.
	// Built once at flag load time to avoid reconstructing FlagProperty/PropertyGroup
	// from map[string]any on every cohort evaluation.
	ParsedValues []parsedPropertyValue `json:"-"`
}
```

PropertyGroup describes a nested property group used by cohorts and flag conditions.

### `RequestContext`

```go
type RequestContext struct {
	// DistinctId is the request-scoped user distinct ID.
	DistinctId string
	// SessionId is the request-scoped PostHog session ID.
	SessionId string
	// Properties are request-scoped properties merged into capture and exception events.
	Properties Properties
}
```

RequestContext carries request-scoped PostHog metadata that is applied to capture and exception events enqueued with EnqueueWithContext.

DistinctId and SessionId usually come from PostHog tracing headers. Properties usually contain safe request metadata such as $current\_url, $request\_method, $request\_path, $user\_agent, and $ip.

#### `posthog.ExtractRequestContext`

```go
func ExtractRequestContext(r *http.Request, captureTracingHeaders bool) RequestContext
```

ExtractRequestContext extracts sanitized PostHog request context from an HTTP request. Request metadata is always extracted. Tracing headers are only read when captureTracingHeaders is true.

#### `posthog.RequestContextFromContext`

```go
func RequestContextFromContext(ctx context.Context) (RequestContext, bool)
```

RequestContextFromContext returns the PostHog request metadata attached to ctx, if any.

### `RequestContextOption`

```go
type RequestContextOption func(*RequestContextOptions)
```

RequestContextOption customizes request context middleware.

#### `posthog.WithCapturePanics`

```go
func WithCapturePanics(client EnqueueClient) RequestContextOption
```

WithCapturePanics configures request context middleware to capture downstream panics as PostHog exception events using client, then re-panic with the original value.

#### `posthog.WithCaptureTracingHeaders`

```go
func WithCaptureTracingHeaders(enabled bool) RequestContextOption
```

WithCaptureTracingHeaders configures whether request context middleware reads PostHog tracing headers.

### `RequestContextOptions`

```go
type RequestContextOptions struct {
	// CaptureTracingHeaders controls whether X-PostHog-Distinct-Id and X-PostHog-Session-Id
	// are read into request-scoped analytics context. It defaults to true in NewRequestContextMiddleware.
	// When disabled, the middleware still attaches request metadata to the request context.
	CaptureTracingHeaders bool

	// CapturePanics controls whether NewRequestContextMiddleware captures downstream panics as
	// PostHog exception events before re-panicking. It defaults to false.
	CapturePanics bool

	// PanicCaptureClient receives panic exception events when CapturePanics is enabled.
	PanicCaptureClient EnqueueClient
}
```

RequestContextOptions configures NewRequestContextMiddleware.

### `RequiresServerEvaluationError`

```go
type RequiresServerEvaluationError struct {
	// Reason is why local evaluation could not resolve the flag.
	Reason UnresolvedFlagReason
}
```

RequiresServerEvaluationError is returned when feature flag evaluation requires server-side data that is not available locally (e.g., static cohorts, experience continuity). This error should propagate immediately to trigger API fallback, unlike InconclusiveMatchError which allows trying other conditions.

#### `RequiresServerEvaluationError.Error`

```go
func (e *RequiresServerEvaluationError) Error() string
```

Error returns the reason server-side evaluation is required.

### `SendEmailResult`

```go
type SendEmailResult struct {
	// ID is the queued email's message ID.
	ID string
	// Replayed is true when PostHog had already accepted this idempotency key
	// and returned the first send's result.
	Replayed bool
	// Warnings are logged through Config.Logger as well.
	Warnings []EmailWarning
}
```

SendEmailResult is an email that PostHog queued.

### `SendFeatureFlagsBool`

```go
type SendFeatureFlagsBool bool
```

SendFeatureFlagsBool wraps a boolean value to implement SendFeatureFlagsValue.

#### `SendFeatureFlagsBool.GetOptions`

```go
func (b SendFeatureFlagsBool) GetOptions() *SendFeatureFlagsOptions
```

GetOptions returns nil because SendFeatureFlagsBool has no additional options.

#### `SendFeatureFlagsBool.ShouldSend`

```go
func (b SendFeatureFlagsBool) ShouldSend() bool
```

ShouldSend reports the wrapped boolean value.

### `SendFeatureFlagsOptions`

```go
type SendFeatureFlagsOptions struct {
	// OnlyEvaluateLocally forces evaluation to use locally loaded flag definitions only.
	OnlyEvaluateLocally bool
	// DeviceId provides a device_id for remote flag evaluation requests.
	DeviceId *string
	// PersonProperties provides explicit person properties for flag evaluation.
	PersonProperties Properties
	// GroupProperties provides explicit group properties for flag evaluation.
	GroupProperties map[string]Properties
}
```

SendFeatureFlagsOptions allows granular control over legacy feature flag evaluation for Capture. Deprecated: Prefer Client.EvaluateFlags and Capture.Flags so captures use the exact flag snapshot your application branched on without another /flags request.

#### `SendFeatureFlagsOptions.GetOptions`

```go
func (opts *SendFeatureFlagsOptions) GetOptions() *SendFeatureFlagsOptions
```

GetOptions returns opts so Capture can pass the options to feature flag evaluation.

#### `SendFeatureFlagsOptions.ShouldSend`

```go
func (opts *SendFeatureFlagsOptions) ShouldSend() bool
```

ShouldSend reports true when opts is non-nil.

### `SendFeatureFlagsValue`

```go
type SendFeatureFlagsValue interface {
	// ShouldSend reports whether Enqueue should attach feature flag values to the Capture event.
	ShouldSend() bool
	// GetOptions returns optional feature flag evaluation parameters, or nil for boolean-only values.
	GetOptions() *SendFeatureFlagsOptions
}
```

SendFeatureFlagsValue defines the legacy Capture.SendFeatureFlags configuration interface.

#### `posthog.SendFeatureFlags`

```go
func SendFeatureFlags(enabled bool) SendFeatureFlagsValue
```

SendFeatureFlags converts enabled into a legacy Capture.SendFeatureFlags value. Deprecated: Prefer Client.EvaluateFlags and Capture.Flags.

#### `posthog.SendFeatureFlagsWithOptions`

```go
func SendFeatureFlagsWithOptions(opts *SendFeatureFlagsOptions) SendFeatureFlagsValue
```

SendFeatureFlagsWithOptions wraps legacy feature flag capture options. Deprecated: Prefer Client.EvaluateFlags and Capture.Flags.

### `SlogCaptureHandler`

```go
type SlogCaptureHandler struct {
	// contains filtered or unexported fields
}
```

SlogCaptureHandler wraps a slog.Handler and mirrors qualifying records to PostHog error tracking using client.Enqueue(Exception{...}).

#### `SlogCaptureHandler.Enabled`

```go
func (h *SlogCaptureHandler) Enabled(ctx context.Context, level slog.Level) bool
```

Enabled reports whether either the wrapped handler or PostHog capture wants records at level.

#### `SlogCaptureHandler.Handle`

```go
func (h *SlogCaptureHandler) Handle(ctx context.Context, r slog.Record) error
```

Handle forwards the record to the wrapped handler and captures qualifying records as exceptions. Enqueue errors are ignored so logging remains non-intrusive.

#### `SlogCaptureHandler.WithAttrs`

```go
func (h *SlogCaptureHandler) WithAttrs(attrs []slog.Attr) slog.Handler
```

WithAttrs returns a handler with attrs applied to the wrapped handler.

#### `SlogCaptureHandler.WithGroup`

```go
func (h *SlogCaptureHandler) WithGroup(name string) slog.Handler
```

WithGroup returns a handler with name applied to the wrapped handler's group.

### `SlogOption`

```go
type SlogOption func(*captureConfig)
```

SlogOption customizes NewSlogCaptureHandler.

#### `posthog.WithDescriptionExtractor`

```go
func WithDescriptionExtractor(extractor DescriptionExtractor) SlogOption
```

WithDescriptionExtractor sets the DescriptionExtractor used for captured exceptions. The extractor parameter must be non-nil.

#### `posthog.WithDistinctIDFn`

```go
func WithDistinctIDFn(fn func(ctx context.Context, r slog.Record) string) SlogOption
```

WithDistinctIDFn sets the function used to resolve the exception DistinctId. The fn parameter must be non-nil. If fn returns an empty string, the slog record is not captured.

#### `posthog.WithFingerprintFn`

```go
func WithFingerprintFn(fn func(ctx context.Context, r slog.Record) *string) SlogOption
```

WithFingerprintFn sets the function used to compute an optional exception fingerprint. The fn parameter must be non-nil.

#### `posthog.WithMinCaptureLevel`

```go
func WithMinCaptureLevel(l slog.Level) SlogOption
```

WithMinCaptureLevel sets the minimum slog level captured as a PostHog exception. Records below this level are still passed to the wrapped handler.

#### `posthog.WithPropertiesFn`

```go
func WithPropertiesFn(fn func(ctx context.Context, r slog.Record) Properties) SlogOption
```

WithPropertiesFn sets a function that returns custom properties for captured exceptions. Built-in exception properties take precedence if keys collide.

#### `posthog.WithSkip`

```go
func WithSkip(n int) SlogOption
```

WithSkip sets how many stack frames the stack trace extractor should skip. Values less than or equal to zero are ignored.

#### `posthog.WithStackTraceExtractor`

```go
func WithStackTraceExtractor(extractor StackTraceExtractor) SlogOption
```

WithStackTraceExtractor sets the StackTraceExtractor used for captured exceptions. The extractor parameter must be non-nil.

### `StackFrame`

```go
type StackFrame struct {
	// Filename is the source file path for the frame.
	Filename string `json:"filename"`
	// LineNo is the one-based source line number.
	LineNo int `json:"lineno"`
	// Function is the fully qualified function name.
	Function string `json:"function"`
	// InApp reports whether the frame is considered application code.
	InApp bool `json:"in_app"`
	// Synthetic reports whether the frame was synthesized by instrumentation.
	Synthetic bool `json:"synthetic"`
	// Platform identifies the runtime platform; plain Go frames use "go",
	// frames with raw addresses for server-side symbolication use "native".
	Platform string `json:"platform"`
	// Lang is a display-language hint for "native" frames; Go frames use "go".
	Lang string `json:"lang,omitempty"`
	// InstructionAddr is the raw return address for the frame's physical
	// group, as hex. The server symbolicates it against uploaded debug
	// symbols.
	InstructionAddr string `json:"instruction_addr,omitempty"`
	// SymbolAddr is the start address of the enclosing function, as hex.
	SymbolAddr string `json:"symbol_addr,omitempty"`
	// ImageAddr is the load address of the image containing the instruction.
	ImageAddr string `json:"image_addr,omitempty"`
	// ClientResolved reports that Function, Filename, and LineNo were
	// resolved in-process from the Go runtime's symbol table.
	ClientResolved bool `json:"client_resolved,omitempty"`
	// Inline marks a frame the runtime synthesized for a call inlined into
	// the preceding physical frame, which carries the same InstructionAddr.
	// The server resolves the group's address once and either replaces the
	// whole group with its own expansion or keeps the client frames verbatim.
	Inline bool `json:"inline,omitempty"`
}
```

StackFrame represents a single "Frame" within a stack trace. Documentation about the available fields can be found here: [https://github.com/PostHog/posthog/blob/39b9326320c23acbdc6e96a8beb41b30d3c99099/rust/cymbal/src/langs/go.rs#L7](https://github.com/PostHog/posthog/blob/39b9326320c23acbdc6e96a8beb41b30d3c99099/rust/cymbal/src/langs/go.rs#L7)

### `StackTraceExtractor`

```go
type StackTraceExtractor interface {
	// GetStackTrace returns a PostHog-compatible stack trace.
	//
	// The skip parameter controls how many leading frames to omit before
	// recording. Use it to drop extractor/logging internals and start at the
	// application call site. For example, a skip of 3–5 is typically enough to
	// hide wrapper layers when called from a slog handler.
	GetStackTrace(skip int) *ExceptionStacktrace
}
```

StackTraceExtractor produces a stack trace for the current goroutine to enrich captured exceptions with call-site context.

### `TemplateEmail`

```go
type TemplateEmail struct {
	// To is one recipient email address.
	To string
	// TemplateID is the UUID of the template.
	TemplateID string
	// TemplateData fills the template's {{ variables.* }} placeholders.
	TemplateData map[string]interface{}
	// DistinctID is the recipient's distinct ID in your product. The email's
	// events go to this person. Without it, they go to a person whose distinct
	// ID is the email address.
	DistinctID string
	// IdempotencyKey is 1 to 255 visible ASCII characters. A send with a key
	// that PostHog already accepted queues nothing and returns the first send's
	// result. Without it, the client makes a UUID that covers its own retries.
	// Pass a key derived from what the email is for, such as
	// "welcome:user_123", to cover retries outside this call too.
	IdempotencyKey string
	// MaxRetries overrides Config.EmailRequestMaxRetries for this send.
	// Ptr(0) turns retries off.
	MaxRetries *int
}
```

TemplateEmail sends an email template made transactional in PostHog, by its ID. The template sets its own sender, subject and content, and follows the project's engagement setting.

### `Ticker`

```go
type Ticker struct {
	// C receives the time for each backoff tick and is closed after Stop.
	C <-chan time.Time
}
```

Ticker delivers ticks using successive durations from a Backoff.

#### `Ticker.Stop`

```go
func (t *Ticker) Stop()
```

Stop stops the ticker goroutine and closes C. Stop should be called at most once.

### `UnresolvedFlagReason`

```go
type UnresolvedFlagReason string
```

UnresolvedFlagReason explains why local evaluation could not resolve a flag. Experience continuity and unsupported definitions come from the flag's definition, missing context from the evaluation call, and unresolved dependencies from a flag the definition depends on.

```go
const (
	// UnresolvedFlagReasonExperienceContinuity means the flag has experience continuity
	// enabled, which local evaluation never resolves.
	UnresolvedFlagReasonExperienceContinuity UnresolvedFlagReason = "experience_continuity"
	// UnresolvedFlagReasonUnsupportedDefinition means the flag uses something local
	// evaluation does not support, such as a static cohort, an unknown operator, a
	// malformed value, or a missing or circular flag dependency.
	UnresolvedFlagReasonUnsupportedDefinition UnresolvedFlagReason = "unsupported_definition"
	// UnresolvedFlagReasonUnresolvedDependency means a flag this flag depends on has a
	// loaded definition but local evaluation could not resolve it.
	UnresolvedFlagReasonUnresolvedDependency UnresolvedFlagReason = "unresolved_dependency"
	// UnresolvedFlagReasonMissingContext means the call did not pass a property, group
	// property or device id the flag needs, or passed it in a form local evaluation
	// cannot use.
	UnresolvedFlagReasonMissingContext UnresolvedFlagReason = "missing_context"
)
```

### `Variants`

```go
type Variants struct {
	// Variants is the ordered list of possible flag variants.
	Variants []FlagVariant `json:"variants"`
}
```

Variants contains all variants configured for a multivariate feature flag.
