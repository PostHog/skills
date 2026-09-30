# PostHog sveltekit Example Project

Repository: https://github.com/PostHog/context-mill
Path: example-apps/sveltekit

---

## README.md

# SvelteKit PostHog example

This example demonstrates how to integrate PostHog with a SvelteKit application, including:

- Client-side PostHog initialization using SvelteKit hooks
- Server-side PostHog tracking with the Node.js SDK
- Reverse proxy to avoid ad blockers
- User identification and event tracking
- Error tracking with `captureException`
- Session replay configuration

## Getting started

### 1. Install dependencies

```bash
npm install
```

### 2. Configure environment variables

Copy the example environment file and add your PostHog credentials:

```bash
cp .env.example .env
```

Edit `.env` with your PostHog project token:

```
PUBLIC_POSTHOG_PROJECT_TOKEN=your_posthog_project_token_here
PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
```

You can find your project token in your [PostHog project settings](https://app.posthog.com/project/settings).

### 3. Run the development server

```bash
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) to view the app.

## Project structure

```
src/
├── lib/
│   ├── auth.svelte.ts              # Auth context with Svelte 5 runes
│   ├── components/
│   │   └── Header.svelte           # Navigation component
│   └── server/
│       └── posthog.ts              # Server-side PostHog singleton
├── routes/
│   ├── +layout.svelte              # Root layout with auth provider
│   ├── +page.svelte                # Home/login page
│   ├── burrito/
│   │   └── +page.svelte            # Event tracking demo
│   ├── profile/
│   │   └── +page.svelte            # Error tracking demo
│   └── api/
│       └── auth/
│           └── login/
│               └── +server.ts      # Login API with server-side tracking
├── hooks.client.ts                 # Client-side PostHog init + error handling
├── hooks.server.ts                 # Server hooks with reverse proxy
├── app.css                         # Global styles
└── app.html                        # HTML template
```

## Key integration points

### Client-side initialization (`src/hooks.client.ts`)

PostHog is initialized in the SvelteKit client hooks `init` function, which runs once when the app starts:

```typescript
import posthog from 'posthog-js';

export async function init() {
  posthog.init(PUBLIC_POSTHOG_PROJECT_TOKEN, {
    api_host: '/ingest',
    ui_host: 'https://us.posthog.com',
    defaults: '2026-01-30',
    capture_exceptions: true
  });
}
```

### Server-side tracking (`src/lib/server/posthog.ts`)

A singleton pattern ensures one PostHog client instance for server-side tracking:

```typescript
import { PostHog } from 'posthog-node';

let posthogClient: PostHog | null = null;

export function getPostHogClient() {
  if (!posthogClient) {
    posthogClient = new PostHog(PUBLIC_POSTHOG_PROJECT_TOKEN, {
      host: PUBLIC_POSTHOG_HOST,
      flushAt: 1,
      flushInterval: 0
    });
  }
  return posthogClient;
}
```

### Reverse proxy (`src/hooks.server.ts`)

The server hooks handle proxies requests through `/ingest` to avoid ad blockers:

```typescript
export const handle: Handle = async ({ event, resolve }) => {
  if (event.url.pathname.startsWith('/ingest')) {
    const pathname = event.url.pathname.replace('/ingest', '');
    const host = pathname.startsWith('/static')
      ? 'https://us-assets.i.posthog.com'
      : 'https://us.i.posthog.com';
    // Proxy to PostHog...
  }
  return resolve(event);
};
```

### User identification

When a user logs in, they are identified in PostHog:

```typescript
import posthog from 'posthog-js';

// On login
posthog.identify(userId, { username });
posthog.capture('user_logged_in', { username });

// On logout
posthog.capture('user_logged_out');
posthog.reset();
```

### Error tracking

Errors are automatically captured via the `handleError` hook:

```typescript
export const handleError: HandleClientError = async ({ error }) => {
  posthog.captureException(error);
  return { message: 'An error occurred' };
};
```

You can also manually capture errors:

```typescript
try {
  // Some operation
} catch (err) {
  posthog.captureException(err);
}
```

### Session replay configuration

For session replay to work correctly, add this to `svelte.config.js`:

```javascript
export default {
  kit: {
    paths: {
      relative: false
    }
  }
};
```

## Features demonstrated

1. **Login page** (`/`) - User authentication with PostHog identification
2. **Burrito page** (`/burrito`) - Custom event tracking with properties
3. **Profile page** (`/profile`) - Error tracking demonstration

## Learn more

- [PostHog Svelte documentation](https://posthog.com/docs/libraries/svelte)
- [PostHog SvelteKit proxy setup](https://posthog.com/docs/advanced/proxy/sveltekit)
- [SvelteKit documentation](https://svelte.dev/docs/kit)

---

## .env.example

```example
# PostHog configuration
# Get your PostHog project token from: https://app.posthog.com/project/settings
PUBLIC_POSTHOG_PROJECT_TOKEN=your_posthog_project_token_here
PUBLIC_POSTHOG_HOST=https://us.i.posthog.com

```

---

## .npmrc

```
engine-strict=true
min-release-age=7

```

---

## .svelte-kit/ambient.d.ts

```ts

// this file is generated — do not edit it


/// <reference types="@sveltejs/kit" />

/**
 * This module provides access to environment variables that are injected _statically_ into your bundle at build time and are limited to _private_ access.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Static environment variables are [loaded by Vite](https://vitejs.dev/guide/env-and-mode.html#env-files) from `.env` files and `process.env` at build time and then statically injected into your bundle at build time, enabling optimisations like dead code elimination.
 * 
 * **_Private_ access:**
 * 
 * - This module cannot be imported into client-side code
 * - This module only includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured)
 * 
 * For example, given the following build time environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { ENVIRONMENT, PUBLIC_BASE_URL } from '$env/static/private';
 * 
 * console.log(ENVIRONMENT); // => "production"
 * console.log(PUBLIC_BASE_URL); // => throws error during build
 * ```
 * 
 * The above values will be the same _even if_ different values for `ENVIRONMENT` or `PUBLIC_BASE_URL` are set at runtime, as they are statically replaced in your code with their build time values.
 */
declare module '$env/static/private' {
	export const CLAUDE_CODE_ENABLE_ASK_USER_QUESTION_TOOL: string;
	export const CLAUDE_CODE_EMIT_TOOL_USE_SUMMARIES: string;
	export const NoDefaultCurrentDirectoryInExePath: string;
	export const CLAUDE_CODE_ENTRYPOINT: string;
	export const CLAUDE_EFFORT: string;
	export const BAGGAGE: string;
	export const CLAUDE_CODE_OAUTH_SCOPES: string;
	export const SHELL: string;
	export const TMPDIR: string;
	export const CLAUDE_CODE_CHILD_SESSION: string;
	export const CLAUDE_AGENT_SDK_VERSION: string;
	export const MallocNanoZone: string;
	export const USE_LOCAL_OAUTH: string;
	export const CLAUDE_CODE_SDK_HAS_OAUTH_REFRESH: string;
	export const GIT_EDITOR: string;
	export const AI_AGENT: string;
	export const USER: string;
	export const API_TIMEOUT_MS: string;
	export const COMMAND_MODE: string;
	export const SSH_AUTH_SOCK: string;
	export const __CF_USER_TEXT_ENCODING: string;
	export const PATH: string;
	export const MCP_CONNECTION_NONBLOCKING: string;
	export const __CFBundleIdentifier: string;
	export const PWD: string;
	export const NODE_PATH: string;
	export const NODE_USE_SYSTEM_CA: string;
	export const XPC_FLAGS: string;
	export const XPC_SERVICE_NAME: string;
	export const SHLVL: string;
	export const HOME: string;
	export const ANTHROPIC_BASE_URL: string;
	export const CLAUDE_CODE_DISABLE_CRON: string;
	export const CLAUDE_CODE_EXECPATH: string;
	export const DISABLE_MICROCOMPACT: string;
	export const LOGNAME: string;
	export const COREPACK_ENABLE_AUTO_PIN: string;
	export const CLAUDE_CODE_SDK_HAS_HOST_AUTH_REFRESH: string;
	export const DISABLE_AUTOUPDATER: string;
	export const CLAUDE_CODE_SESSION_ID: string;
	export const CLAUDECODE: string;
	export const USE_STAGING_OAUTH: string;
	export const NODE_ENV: string;
}

/**
 * This module provides access to environment variables that are injected _statically_ into your bundle at build time and are _publicly_ accessible.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Static environment variables are [loaded by Vite](https://vitejs.dev/guide/env-and-mode.html#env-files) from `.env` files and `process.env` at build time and then statically injected into your bundle at build time, enabling optimisations like dead code elimination.
 * 
 * **_Public_ access:**
 * 
 * - This module _can_ be imported into client-side code
 * - **Only** variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`) are included
 * 
 * For example, given the following build time environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { ENVIRONMENT, PUBLIC_BASE_URL } from '$env/static/public';
 * 
 * console.log(ENVIRONMENT); // => throws error during build
 * console.log(PUBLIC_BASE_URL); // => "http://site.com"
 * ```
 * 
 * The above values will be the same _even if_ different values for `ENVIRONMENT` or `PUBLIC_BASE_URL` are set at runtime, as they are statically replaced in your code with their build time values.
 */
declare module '$env/static/public' {
	export const PUBLIC_POSTHOG_PROJECT_TOKEN: string;
	export const PUBLIC_POSTHOG_HOST: string;
}

/**
 * This module provides access to environment variables set _dynamically_ at runtime and that are limited to _private_ access.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Dynamic environment variables are defined by the platform you're running on. For example if you're using [`adapter-node`](https://github.com/sveltejs/kit/tree/main/packages/adapter-node) (or running [`vite preview`](https://svelte.dev/docs/kit/cli)), this is equivalent to `process.env`.
 * 
 * **_Private_ access:**
 * 
 * - This module cannot be imported into client-side code
 * - This module includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured)
 * 
 * > [!NOTE] In `dev`, `$env/dynamic` includes environment variables from `.env`. In `prod`, this behavior will depend on your adapter.
 * 
 * > [!NOTE] To get correct types, environment variables referenced in your code should be declared (for example in an `.env` file), even if they don't have a value until the app is deployed:
 * >
 * > ```env
 * > MY_FEATURE_FLAG=
 * > ```
 * >
 * > You can override `.env` values from the command line like so:
 * >
 * > ```sh
 * > MY_FEATURE_FLAG="enabled" npm run dev
 * > ```
 * 
 * For example, given the following runtime environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://site.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { env } from '$env/dynamic/private';
 * 
 * console.log(env.ENVIRONMENT); // => "production"
 * console.log(env.PUBLIC_BASE_URL); // => undefined
 * ```
 */
declare module '$env/dynamic/private' {
	export const env: {
		CLAUDE_CODE_ENABLE_ASK_USER_QUESTION_TOOL: string;
		CLAUDE_CODE_EMIT_TOOL_USE_SUMMARIES: string;
		NoDefaultCurrentDirectoryInExePath: string;
		CLAUDE_CODE_ENTRYPOINT: string;
		CLAUDE_EFFORT: string;
		BAGGAGE: string;
		CLAUDE_CODE_OAUTH_SCOPES: string;
		SHELL: string;
		TMPDIR: string;
		CLAUDE_CODE_CHILD_SESSION: string;
		CLAUDE_AGENT_SDK_VERSION: string;
		MallocNanoZone: string;
		USE_LOCAL_OAUTH: string;
		CLAUDE_CODE_SDK_HAS_OAUTH_REFRESH: string;
		GIT_EDITOR: string;
		AI_AGENT: string;
		USER: string;
		API_TIMEOUT_MS: string;
		COMMAND_MODE: string;
		SSH_AUTH_SOCK: string;
		__CF_USER_TEXT_ENCODING: string;
		PATH: string;
		MCP_CONNECTION_NONBLOCKING: string;
		__CFBundleIdentifier: string;
		PWD: string;
		NODE_PATH: string;
		NODE_USE_SYSTEM_CA: string;
		XPC_FLAGS: string;
		XPC_SERVICE_NAME: string;
		SHLVL: string;
		HOME: string;
		ANTHROPIC_BASE_URL: string;
		CLAUDE_CODE_DISABLE_CRON: string;
		CLAUDE_CODE_EXECPATH: string;
		DISABLE_MICROCOMPACT: string;
		LOGNAME: string;
		COREPACK_ENABLE_AUTO_PIN: string;
		CLAUDE_CODE_SDK_HAS_HOST_AUTH_REFRESH: string;
		DISABLE_AUTOUPDATER: string;
		CLAUDE_CODE_SESSION_ID: string;
		CLAUDECODE: string;
		USE_STAGING_OAUTH: string;
		NODE_ENV: string;
		[key: `PUBLIC_${string}`]: undefined;
		[key: `${string}`]: string | undefined;
	}
}

/**
 * This module provides access to environment variables set _dynamically_ at runtime and that are _publicly_ accessible.
 * 
 * |         | Runtime                                                                    | Build time                                                               |
 * | ------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
 * | Private | [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private) | [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private) |
 * | Public  | [`$env/dynamic/public`](https://svelte.dev/docs/kit/$env-dynamic-public)   | [`$env/static/public`](https://svelte.dev/docs/kit/$env-static-public)   |
 * 
 * Dynamic environment variables are defined by the platform you're running on. For example if you're using [`adapter-node`](https://github.com/sveltejs/kit/tree/main/packages/adapter-node) (or running [`vite preview`](https://svelte.dev/docs/kit/cli)), this is equivalent to `process.env`.
 * 
 * **_Public_ access:**
 * 
 * - This module _can_ be imported into client-side code
 * - **Only** variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`) are included
 * 
 * > [!NOTE] In `dev`, `$env/dynamic` includes environment variables from `.env`. In `prod`, this behavior will depend on your adapter.
 * 
 * > [!NOTE] To get correct types, environment variables referenced in your code should be declared (for example in an `.env` file), even if they don't have a value until the app is deployed:
 * >
 * > ```env
 * > MY_FEATURE_FLAG=
 * > ```
 * >
 * > You can override `.env` values from the command line like so:
 * >
 * > ```sh
 * > MY_FEATURE_FLAG="enabled" npm run dev
 * > ```
 * 
 * For example, given the following runtime environment:
 * 
 * ```env
 * ENVIRONMENT=production
 * PUBLIC_BASE_URL=http://example.com
 * ```
 * 
 * With the default `publicPrefix` and `privatePrefix`:
 * 
 * ```ts
 * import { env } from '$env/dynamic/public';
 * console.log(env.ENVIRONMENT); // => undefined, not public
 * console.log(env.PUBLIC_BASE_URL); // => "http://example.com"
 * ```
 * 
 * ```
 * 
 * ```
 */
declare module '$env/dynamic/public' {
	export const env: {
		PUBLIC_POSTHOG_PROJECT_TOKEN: string;
		PUBLIC_POSTHOG_HOST: string;
		[key: `PUBLIC_${string}`]: string | undefined;
	}
}

```

---

## .svelte-kit/env.d.ts

```ts
// See https://svelte.dev/docs/kit/environment-variables for more information
```

---

## .svelte-kit/generated/client/app.js

```js
// in dev, this makes Vite inject its client as this module's first dependency,
// so that global constant replacements are installed before any other module
// (including user hooks) evaluates. In build it's inert.
import.meta.hot;

import * as client_hooks from '../../../src/hooks.client.ts';


export { matchers } from './matchers.js';

export const nodes = [
	() => import('./nodes/0'),
	() => import('./nodes/1'),
	() => import('./nodes/2'),
	() => import('./nodes/3'),
	() => import('./nodes/4')
];

export const server_loads = [];

export const dictionary = {
		"/": [2],
		"/burrito": [3],
		"/profile": [4]
	};

export const hooks = {
	handleError: client_hooks.handleError || (({ error }) => { console.error(error) }),
	init: client_hooks.init,
	reroute: (() => {}),
	transport: {}
};

export const decoders = Object.fromEntries(Object.entries(hooks.transport).map(([k, v]) => [k, v.decode]));
export const encoders = Object.fromEntries(Object.entries(hooks.transport).map(([k, v]) => [k, v.encode]));

export const hash = false;

export const decode = (type, value) => decoders[type](value);

export { default as root } from '../root.js';

export const get_error_template = () => import('../shared/error-template.js').then(m => m.default);
```

---

## .svelte-kit/generated/client/matchers.js

```js
export const matchers = {};
```

---

## .svelte-kit/generated/client/nodes/0.js

```js
export { default as component } from "../../../../src/routes/+layout.svelte";
```

---

## .svelte-kit/generated/client/nodes/1.js

```js
export { default as component } from "../../../../node_modules/.pnpm/@sveltejs+kit@2.69.2_@sveltejs+vite-plugin-svelte@6.2.4_svelte@5.56.4_vite@7.3.6__svelt_988192f2a76a9c05ef6ef7cb284211b3/node_modules/@sveltejs/kit/src/runtime/components/svelte-5/error.svelte";
```

---

## .svelte-kit/generated/client/nodes/2.js

```js
export { default as component } from "../../../../src/routes/+page.svelte";
```

---

## .svelte-kit/generated/client/nodes/3.js

```js
export { default as component } from "../../../../src/routes/burrito/+page.svelte";
```

---

## .svelte-kit/generated/client/nodes/4.js

```js
export { default as component } from "../../../../src/routes/profile/+page.svelte";
```

---

## .svelte-kit/generated/root.js

```js
import { asClassComponent } from 'svelte/legacy';
import Root from './root.svelte';
export default asClassComponent(Root);
```

---

## .svelte-kit/generated/root.svelte

```svelte
<!-- This file is generated by @sveltejs/kit — do not edit it! -->
<svelte:options runes={true} />
<script>
	import { setContext, onMount, tick } from 'svelte';
	import { browser } from '$app/env';

	// stores
	let { stores, page, constructors, components = [], form, data_0 = null, data_1 = null } = $props();

	if (!browser) {
		// svelte-ignore state_referenced_locally
		setContext('__svelte__', stores);
	}

	if (browser) {
		$effect.pre(() => stores.page.set(page));
	} else {
		// svelte-ignore state_referenced_locally
		stores.page.set(page);
	}
	$effect(() => {
		stores;page;constructors;components;form;data_0;data_1;
		stores.page.notify();
	});

	let mounted = $state(false);
	let navigated = $state(false);
	let title = $state(null);

	onMount(() => {
		const unsubscribe = stores.page.subscribe(() => {
			if (mounted) {
				navigated = true;
				tick().then(() => {
					title = document.title || 'untitled page';
				});
			}
		});

		mounted = true;
		return unsubscribe;
	});

	const Pyramid_1=$derived(constructors[1])
</script>

{#if constructors[1]}
	{@const Pyramid_0 = constructors[0]}
							<!-- svelte-ignore binding_property_non_reactive -->
							<Pyramid_0 bind:this={components[0]} data={data_0} {form} params={page.params}>
								<!-- svelte-ignore binding_property_non_reactive -->
										<Pyramid_1 bind:this={components[1]} data={data_1} {form} params={page.params} />
							</Pyramid_0>

{:else}
	{@const Pyramid_0 = constructors[0]}
	<!-- svelte-ignore binding_property_non_reactive -->
	<Pyramid_0 bind:this={components[0]} data={data_0} {form} params={page.params} />

{/if}

{#if mounted}
	<div id="svelte-announcer" aria-live="assertive" aria-atomic="true" style="position: absolute; left: 0; top: 0; clip: rect(0 0 0 0); clip-path: inset(50%); overflow: hidden; white-space: nowrap; width: 1px; height: 1px">
		{#if navigated}
			{title}
		{/if}
	</div>
{/if}
```

---

## .svelte-kit/generated/server/internal.js

```js

import root from '../root.js';
import { set_building, set_prerendering } from '$app/env/internal';
import { set_assets } from '$app/paths/internal/server';
import { set_manifest, set_read_implementation } from '__sveltekit/server';
import { set_private_env, set_public_env } from '../../../node_modules/.pnpm/@sveltejs+kit@2.69.2_@sveltejs+vite-plugin-svelte@6.2.4_svelte@5.56.4_vite@7.3.6__svelt_988192f2a76a9c05ef6ef7cb284211b3/node_modules/@sveltejs/kit/src/runtime/shared-server.js';
import error from '../shared/error-template.js';

export const options = {
	app_template_contains_nonce: false,
	async: false,
	csp: {"mode":"auto","directives":{"upgrade-insecure-requests":false,"block-all-mixed-content":false},"reportOnly":{"upgrade-insecure-requests":false,"block-all-mixed-content":false}},
	csrf_check_origin: true,
	csrf_trusted_origins: [],
	embedded: false,
	env_public_prefix: 'PUBLIC_',
	env_private_prefix: '',
	hash_routing: false,
	hooks: null, // added lazily, via `get_hooks`
	preload_strategy: "modulepreload",
	root,
	service_worker: false,
	service_worker_options: undefined,
	server_error_boundaries: false,
	templates: {
		app: ({ head, body, assets, nonce, env }) => "<!doctype html>\n<html lang=\"en\">\n\t<head>\n\t\t<meta charset=\"utf-8\" />\n\t\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n\t\t" + head + "\n\t</head>\n\t<body data-sveltekit-preload-data=\"hover\">\n\t\t<div style=\"display: contents\">" + body + "</div>\n\t</body>\n</html>\n",
		error
	},
	version_hash: "55a5mc"
};

export async function get_hooks() {
	let handle;
	let handleFetch;
	let handleError;
	let handleValidationError;
	let init;
	({ handle, handleFetch, handleError, handleValidationError, init } = await import("../../../src/hooks.server.ts"));

	let reroute;
	let transport;
	

	return {
		handle,
		handleFetch,
		handleError,
		handleValidationError,
		init,
		reroute,
		transport
	};
}

export { set_assets, set_building, set_manifest, set_prerendering, set_private_env, set_public_env, set_read_implementation };

```

---

## .svelte-kit/generated/shared/error-template.js

```js
export default ({ status, message }) => "<!doctype html>\n<html lang=\"en\">\n\t<head>\n\t\t<meta charset=\"utf-8\" />\n\t\t<title>" + message + "</title>\n\n\t\t<style>\n\t\t\tbody {\n\t\t\t\t--bg: white;\n\t\t\t\t--fg: #222;\n\t\t\t\t--divider: #ccc;\n\t\t\t\tbackground: var(--bg);\n\t\t\t\tcolor: var(--fg);\n\t\t\t\tfont-family:\n\t\t\t\t\tsystem-ui,\n\t\t\t\t\t-apple-system,\n\t\t\t\t\tBlinkMacSystemFont,\n\t\t\t\t\t'Segoe UI',\n\t\t\t\t\tRoboto,\n\t\t\t\t\tOxygen,\n\t\t\t\t\tUbuntu,\n\t\t\t\t\tCantarell,\n\t\t\t\t\t'Open Sans',\n\t\t\t\t\t'Helvetica Neue',\n\t\t\t\t\tsans-serif;\n\t\t\t\tdisplay: flex;\n\t\t\t\talign-items: center;\n\t\t\t\tjustify-content: center;\n\t\t\t\theight: 100vh;\n\t\t\t\tmargin: 0;\n\t\t\t}\n\n\t\t\t.error {\n\t\t\t\tdisplay: flex;\n\t\t\t\talign-items: center;\n\t\t\t\tmax-width: 32rem;\n\t\t\t\tmargin: 0 1rem;\n\t\t\t}\n\n\t\t\t.status {\n\t\t\t\tfont-weight: 200;\n\t\t\t\tfont-size: 3rem;\n\t\t\t\tline-height: 1;\n\t\t\t\tposition: relative;\n\t\t\t\ttop: -0.05rem;\n\t\t\t}\n\n\t\t\t.message {\n\t\t\t\tborder-left: 1px solid var(--divider);\n\t\t\t\tpadding: 0 0 0 1rem;\n\t\t\t\tmargin: 0 0 0 1rem;\n\t\t\t\tmin-height: 2.5rem;\n\t\t\t\tdisplay: flex;\n\t\t\t\talign-items: center;\n\t\t\t}\n\n\t\t\t.message h1 {\n\t\t\t\tfont-weight: 400;\n\t\t\t\tfont-size: 1em;\n\t\t\t\tmargin: 0;\n\t\t\t}\n\n\t\t\t@media (prefers-color-scheme: dark) {\n\t\t\t\tbody {\n\t\t\t\t\t--bg: #222;\n\t\t\t\t\t--fg: #ddd;\n\t\t\t\t\t--divider: #666;\n\t\t\t\t}\n\t\t\t}\n\t\t</style>\n\t</head>\n\t<body>\n\t\t<div class=\"error\">\n\t\t\t<span class=\"status\">" + status + "</span>\n\t\t\t<div class=\"message\">\n\t\t\t\t<h1>" + message + "</h1>\n\t\t\t</div>\n\t\t</div>\n\t</body>\n</html>\n";
```

---

## .svelte-kit/non-ambient.d.ts

```ts

// this file is generated — do not edit it


declare module "svelte/elements" {
	export interface HTMLAttributes<T> {
		'data-sveltekit-keepfocus'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-noscroll'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-preload-code'?:
			| true
			| ''
			| 'eager'
			| 'viewport'
			| 'hover'
			| 'tap'
			| 'off'
			| undefined
			| null;
		'data-sveltekit-preload-data'?: true | '' | 'hover' | 'tap' | 'off' | undefined | null;
		'data-sveltekit-reload'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-replacestate'?: true | '' | 'off' | undefined | null;
	}
}

export {};


declare module "$app/types" {
	type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;

	export interface AppTypes {
		RouteId(): "/" | "/api" | "/api/auth" | "/api/auth/login" | "/burrito" | "/profile";
		RouteParams(): {
			
		};
		LayoutParams(): {
			"/": Record<string, never>;
			"/api": Record<string, never>;
			"/api/auth": Record<string, never>;
			"/api/auth/login": Record<string, never>;
			"/burrito": Record<string, never>;
			"/profile": Record<string, never>
		};
		Pathname(): "/" | "/api/auth/login" | "/burrito" | "/profile";
		ResolvedPathname(): `${"" | `/${string}`}${ReturnType<AppTypes['Pathname']>}`;
		Asset(): "/robots.txt" | string & {};
	}
}
```

---

## .svelte-kit/types/src/routes/$types.d.ts

```ts
import type * as Kit from '@sveltejs/kit';

type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never;
type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;
type RouteParams = {  };
type RouteId = '/';
type MaybeWithVoid<T> = {} extends T ? T | void : T;
export type RequiredKeys<T> = { [K in keyof T]-?: {} extends { [P in K]: T[K] } ? never : K; }[keyof T];
type OutputDataShape<T> = MaybeWithVoid<Omit<App.PageData, RequiredKeys<T>> & Partial<Pick<App.PageData, keyof T & keyof App.PageData>> & Record<string, any>>
type EnsureDefined<T> = T extends null | undefined ? {} : T;
type OptionalUnion<U extends Record<string, any>, A extends keyof U = U extends U ? keyof U : never> = U extends unknown ? { [P in Exclude<A, keyof U>]?: never } & U : never;
export type Snapshot<T = any> = Kit.Snapshot<T>;
type PageParentData = EnsureDefined<LayoutData>;
type LayoutRouteId = RouteId | "/" | "/burrito" | "/profile" | null
type LayoutParams = RouteParams & {  }
type LayoutParentData = EnsureDefined<{}>;

export type PageServerData = null;
export type PageData = Expand<PageParentData>;
export type PageProps = { params: RouteParams; data: PageData }
export type LayoutServerData = null;
export type LayoutData = Expand<LayoutParentData>;
export type LayoutProps = { params: LayoutParams; data: LayoutData; children: import("svelte").Snippet }
```

---

## .svelte-kit/types/src/routes/api/auth/login/$types.d.ts

```ts
import type * as Kit from '@sveltejs/kit';

type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never;
type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;
type RouteParams = {  };
type RouteId = '/api/auth/login';

export type RequestHandler = Kit.RequestHandler<RouteParams, RouteId>;
export type RequestEvent = Kit.RequestEvent<RouteParams, RouteId>;
```

---

## .svelte-kit/types/src/routes/burrito/$types.d.ts

```ts
import type * as Kit from '@sveltejs/kit';

type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never;
type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;
type RouteParams = {  };
type RouteId = '/burrito';
type MaybeWithVoid<T> = {} extends T ? T | void : T;
export type RequiredKeys<T> = { [K in keyof T]-?: {} extends { [P in K]: T[K] } ? never : K; }[keyof T];
type OutputDataShape<T> = MaybeWithVoid<Omit<App.PageData, RequiredKeys<T>> & Partial<Pick<App.PageData, keyof T & keyof App.PageData>> & Record<string, any>>
type EnsureDefined<T> = T extends null | undefined ? {} : T;
type OptionalUnion<U extends Record<string, any>, A extends keyof U = U extends U ? keyof U : never> = U extends unknown ? { [P in Exclude<A, keyof U>]?: never } & U : never;
export type Snapshot<T = any> = Kit.Snapshot<T>;
type PageParentData = EnsureDefined<import('../$types.js').LayoutData>;

export type PageServerData = null;
export type PageData = Expand<PageParentData>;
export type PageProps = { params: RouteParams; data: PageData }
```

---

## .svelte-kit/types/src/routes/profile/$types.d.ts

```ts
import type * as Kit from '@sveltejs/kit';

type Expand<T> = T extends infer O ? { [K in keyof O]: O[K] } : never;
type MatcherParam<M> = M extends (param : string) => param is (infer U extends string) ? U : string;
type RouteParams = {  };
type RouteId = '/profile';
type MaybeWithVoid<T> = {} extends T ? T | void : T;
export type RequiredKeys<T> = { [K in keyof T]-?: {} extends { [P in K]: T[K] } ? never : K; }[keyof T];
type OutputDataShape<T> = MaybeWithVoid<Omit<App.PageData, RequiredKeys<T>> & Partial<Pick<App.PageData, keyof T & keyof App.PageData>> & Record<string, any>>
type EnsureDefined<T> = T extends null | undefined ? {} : T;
type OptionalUnion<U extends Record<string, any>, A extends keyof U = U extends U ? keyof U : never> = U extends unknown ? { [P in Exclude<A, keyof U>]?: never } & U : never;
export type Snapshot<T = any> = Kit.Snapshot<T>;
type PageParentData = EnsureDefined<import('../$types.js').LayoutData>;

export type PageServerData = null;
export type PageData = Expand<PageParentData>;
export type PageProps = { params: RouteParams; data: PageData }
```

---

## src/app.d.ts

```ts
// See https://svelte.dev/docs/kit/types#app.d.ts
// for information about these interfaces
declare global {
	namespace App {
		// interface Error {}
		// interface Locals {}
		// interface PageData {}
		// interface PageState {}
		// interface Platform {}
	}
}

export {};

```

---

## src/app.html

```html
<!doctype html>
<html lang="en">
	<head>
		<meta charset="utf-8" />
		<meta name="viewport" content="width=device-width, initial-scale=1" />
		%sveltekit.head%
	</head>
	<body data-sveltekit-preload-data="hover">
		<div style="display: contents">%sveltekit.body%</div>
	</body>
</html>

```

---

## src/hooks.client.ts

```ts
import posthog from 'posthog-js';
import { PUBLIC_POSTHOG_PROJECT_TOKEN } from '$env/static/public';
import type { HandleClientError } from '@sveltejs/kit';

// Initialize PostHog when the app starts in the browser
export async function init() {
	posthog.init(PUBLIC_POSTHOG_PROJECT_TOKEN, {
		api_host: '/ingest',
		ui_host: 'https://us.posthog.com',
  defaults: '2026-01-30',
		capture_exceptions: true
	});
}

// Capture client-side errors with PostHog
export const handleError: HandleClientError = async ({ error, status, message }) => {
	posthog.captureException(error);

	return {
		message,
		status
	};
};

```

---

## src/hooks.server.ts

```ts
import type { Handle, HandleServerError } from '@sveltejs/kit';
import { getPostHogClient } from '$lib/server/posthog';

// Handle requests - includes reverse proxy for PostHog
export const handle: Handle = async ({ event, resolve }) => {
	const { pathname } = event.url;

	// Reverse proxy for PostHog - route /ingest requests to PostHog servers
	if (pathname.startsWith('/ingest')) {
		const useAssetHost = pathname.startsWith('/ingest/static/') || pathname.startsWith('/ingest/array/')
		const hostname = useAssetHost ? 'us-assets.i.posthog.com' : 'us.i.posthog.com';

		const url = new URL(event.request.url);
		url.protocol = 'https:';
		url.hostname = hostname;
		url.port = '443';
		url.pathname = pathname.replace(/^\/ingest/, '');

		const headers = new Headers(event.request.headers);
		headers.set('host', hostname);
		headers.set('accept-encoding', '');

		const clientIp = event.request.headers.get('x-forwarded-for') || event.getClientAddress();
		if (clientIp) {
			headers.set('x-forwarded-for', clientIp);
		}

		const response = await fetch(url.toString(), {
			method: event.request.method,
			headers,
			body: event.request.body,
			// @ts-expect-error - duplex is required for streaming request bodies
			duplex: 'half'
		});

		return response;
	}

	return resolve(event);
};

// Capture server-side errors with PostHog
export const handleError: HandleServerError = async ({ error, status, message }) => {
	const posthog = getPostHogClient();

	posthog.capture({
		distinctId: 'server',
		event: 'server_error',
		properties: {
			error: error instanceof Error ? error.message : String(error),
			status,
			message
		}
	});

	// handleError runs per request; flush so the enqueued event sends before it returns
	await posthog.flush();

	return {
		message,
		status
	};
};

```

---

## src/lib/auth.svelte.ts

```ts
import { getContext, setContext } from 'svelte';
import posthog from 'posthog-js';
import { browser } from '$app/environment';

export interface User {
	username: string;
	burritoConsiderations: number;
}

const AUTH_KEY = Symbol('auth');

// Class-based auth state using Svelte 5 $state in class fields
// This is the recommended pattern for encapsulating reactive state + behavior
export class AuthState {
	user = $state<User | null>(null);

	constructor() {
		// Restore user from localStorage on creation (browser only)
		if (browser) {
			const storedUsername = localStorage.getItem('currentUser');
			if (storedUsername) {
				this.user = { username: storedUsername, burritoConsiderations: 0 };
			}
		}
	}

	login = async (username: string, password: string): Promise<boolean> => {
		try {
			const response = await fetch('/api/auth/login', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ username, password })
			});

			if (response.ok) {
				const { user: userData } = await response.json();
				this.user = userData as User;

				if (browser) {
					localStorage.setItem('currentUser', username);
					posthog.identify(username, { username });
					posthog.capture('user_logged_in', { username });
				}

				return true;
			}
			return false;
		} catch (error) {
			console.error('Login error:', error);
			return false;
		}
	};

	logout = (): void => {
		if (browser) {
			posthog.capture('user_logged_out');
			posthog.reset();
			localStorage.removeItem('currentUser');
		}
		this.user = null;
	};

	incrementBurritoConsiderations = (): void => {
		if (this.user) {
			this.user = {
				...this.user,
				burritoConsiderations: this.user.burritoConsiderations + 1
			};
		}
	};
}

export function setAuthContext(auth: AuthState) {
	setContext(AUTH_KEY, auth);
}

export function getAuthContext(): AuthState {
	return getContext<AuthState>(AUTH_KEY);
}

```

---

## src/lib/components/Header.svelte

```svelte
<script lang="ts">
	import { getAuthContext } from '$lib/auth.svelte';

	const auth = getAuthContext();
</script>

<header class="header">
	<div class="header-container">
		<nav>
			<a href="/">Home</a>
			{#if auth.user}
				<a href="/burrito">Burrito</a>
				<a href="/profile">Profile</a>
			{/if}
		</nav>
		<div class="user-section">
			{#if auth.user}
				<span>Welcome, {auth.user.username}</span>
				<button class="btn-logout" onclick={() => auth.logout()}>Logout</button>
			{/if}
		</div>
	</div>
</header>

```

---

## src/lib/index.ts

```ts
// place files you want to import through the `$lib` alias in this folder.

```

---

## src/lib/server/posthog.ts

```ts
import { PostHog } from 'posthog-node';
import { PUBLIC_POSTHOG_PROJECT_TOKEN, PUBLIC_POSTHOG_HOST } from '$env/static/public';

let posthogClient: PostHog | null = null;

export function getPostHogClient() {
	if (!posthogClient) {
		posthogClient = new PostHog(PUBLIC_POSTHOG_PROJECT_TOKEN, {
			host: PUBLIC_POSTHOG_HOST,
			flushAt: 1,
			flushInterval: 0
		});
	}
	return posthogClient;
}

export async function shutdownPostHog() {
	if (posthogClient) {
		await posthogClient.shutdown();
	}
}

```

---

## src/routes/+layout.svelte

```svelte
<script lang="ts">
	import { AuthState, setAuthContext } from '$lib/auth.svelte';
	import Header from '$lib/components/Header.svelte';
	import '../app.css';

	let { children } = $props();

	// Create and provide auth context
	const auth = new AuthState();
	setAuthContext(auth);
</script>

<svelte:head>
	<title>Burrito consideration app</title>
	<meta name="description" content="Consider the potential of burritos with PostHog analytics" />
</svelte:head>

<Header />
<main>
	{@render children()}
</main>

```

---

## src/routes/+page.svelte

```svelte
<script lang="ts">
	import { getAuthContext } from '$lib/auth.svelte';

	const auth = getAuthContext();

	let username = $state('');
	let password = $state('');
	let error = $state('');

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';

		try {
			const success = await auth.login(username, password);
			if (success) {
				username = '';
				password = '';
			} else {
				error = 'Please provide both username and password';
			}
		} catch (err) {
			console.error('Login failed:', err);
			error = 'An error occurred during login';
		}
	}
</script>

<div class="container">
	{#if auth.user}
		<h1>Welcome back, {auth.user.username}!</h1>
		<p>You are logged in. Check out the navigation to explore features.</p>
		<ul>
			<li><a href="/burrito">Consider a burrito</a></li>
			<li><a href="/profile">View your profile</a></li>
		</ul>
	{:else}
		<h1>Welcome to Burrito consideration app</h1>
		<p>Sign in to start considering burritos.</p>

		<form class="form" onsubmit={handleSubmit}>
			<div class="form-group">
				<label for="username">Username:</label>
				<input type="text" id="username" bind:value={username} required />
			</div>

			<div class="form-group">
				<label for="password">Password:</label>
				<input type="password" id="password" bind:value={password} required />
			</div>

			{#if error}
				<p class="error">{error}</p>
			{/if}

			<button type="submit" class="btn-primary">Sign In</button>
		</form>

		<p class="note">
			Enter any username and password to sign in. This is a demo app.
		</p>
	{/if}
</div>

```

---

## src/routes/api/auth/login/+server.ts

```ts
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getPostHogClient } from '$lib/server/posthog';

const users = new Map<string, { username: string; burritoConsiderations: number }>();

export const POST: RequestHandler = async ({ request }) => {
	const { username, password } = await request.json();

	if (!username || !password) {
		return json({ error: 'Username and password required' }, { status: 400 });
	}

	let user = users.get(username);
	const isNewUser = !user;

	if (!user) {
		user = { username, burritoConsiderations: 0 };
		users.set(username, user);
	}

	// Capture server-side login event with user context
	const posthog = getPostHogClient();
	posthog.withContext(
		{
			distinctId: username,
			personProperties: {
				username,
				createdAt: isNewUser ? new Date().toISOString() : undefined
			}
		},
		() => {
			posthog.capture({
				event: 'server_login',
				properties: {
					isNewUser,
					source: 'api'
				}
			});
		}
	);

	// Flush events to ensure they're sent
	await posthog.flush();

	return json({ success: true, user });
};

```

---

## src/routes/burrito/+page.svelte

```svelte
<script lang="ts">
	import { goto } from '$app/navigation';
	import { browser } from '$app/environment';
	import posthog from 'posthog-js';
	import { getAuthContext } from '$lib/auth.svelte';

	const auth = getAuthContext();

	let hasConsidered = $state(false);

	// Redirect to home if not logged in
	$effect(() => {
		if (browser && !auth.user) {
			goto('/');
		}
	});

	function handleConsideration() {
		if (!auth.user) return;

		auth.incrementBurritoConsiderations();
		hasConsidered = true;
		setTimeout(() => (hasConsidered = false), 2000);

		// Capture burrito consideration event with PostHog
		posthog.capture('burrito_considered', {
			total_considerations: auth.user.burritoConsiderations,
			username: auth.user.username
		});
	}
</script>

<div class="container">
	{#if auth.user}
		<h1>Burrito consideration zone</h1>
		<p>This is where you consider the infinite potential of burritos.</p>
		<p>Current considerations: <strong>{auth.user.burritoConsiderations}</strong></p>

		<button class="btn-burrito" onclick={handleConsideration}>
			I have considered the burrito potential
		</button>

		{#if hasConsidered}
			<p class="success">
				Thank you for your consideration! Count: {auth.user.burritoConsiderations}
			</p>
		{/if}

		<div class="note">
			<p>Each consideration is tracked as a PostHog event with custom properties.</p>
		</div>
	{:else}
		<p>Please log in to consider burritos.</p>
	{/if}
</div>

```

---

## src/routes/profile/+page.svelte

```svelte
<script lang="ts">
	import { goto } from '$app/navigation';
	import { browser } from '$app/environment';
	import posthog from 'posthog-js';
	import { getAuthContext } from '$lib/auth.svelte';

	const auth = getAuthContext();

	// Redirect to home if not logged in
	$effect(() => {
		if (browser && !auth.user) {
			goto('/');
		}
	});

	function triggerTestError() {
		try {
			throw new Error('Test error for PostHog error tracking');
		} catch (err) {
			posthog.captureException(err);
			console.error('Captured error:', err);
			alert('Error captured and sent to PostHog!');
		}
	}
</script>

<div class="container">
	{#if auth.user}
		<h1>User profile</h1>

		<div class="stats">
			<h2>Your information</h2>
			<p><strong>Username:</strong> {auth.user.username}</p>
			<p><strong>Burrito considerations:</strong> {auth.user.burritoConsiderations}</p>
		</div>

		<h2 style="margin-top: 2rem;">Error tracking demo</h2>
		<p>Click the button below to trigger a test error that will be captured by PostHog.</p>

		<button class="btn-primary" onclick={triggerTestError} style="margin-top: 1rem;">
			Trigger test error (for PostHog)
		</button>

		<div class="note">
			<p>This demonstrates PostHog's error tracking capabilities.</p>
			<p>The error will appear in your PostHog error tracking dashboard.</p>
		</div>
	{:else}
		<p>Please log in to view your profile.</p>
	{/if}
</div>

```

---

## static/robots.txt

```txt
# allow crawling everything by default
User-agent: *
Disallow:

```

---

## svelte.config.js

```js
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
		// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
		// See https://svelte.dev/docs/kit/adapters for more information about adapters.
		adapter: adapter(),
		// Required for PostHog session replay to work correctly with SSR
		paths: {
			relative: false
		}
	}
};

export default config;

```

---

## vite.config.ts

```ts
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()]
});

```

---

