
// this file is generated — do not edit it


/// <reference types="@sveltejs/kit" />

/**
 * Environment variables [loaded by Vite](https://vitejs.dev/guide/env-and-mode.html#env-files) from `.env` files and `process.env`. Like [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private), this module cannot be imported into client-side code. This module only includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured).
 * 
 * _Unlike_ [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private), the values exported from this module are statically injected into your bundle at build time, enabling optimisations like dead code elimination.
 * 
 * ```ts
 * import { API_KEY } from '$env/static/private';
 * ```
 * 
 * Note that all environment variables referenced in your code should be declared (for example in an `.env` file), even if they don't have a value until the app is deployed:
 * 
 * ```
 * MY_FEATURE_FLAG=""
 * ```
 * 
 * You can override `.env` values from the command line like so:
 * 
 * ```sh
 * MY_FEATURE_FLAG="enabled" npm run dev
 * ```
 */
declare module '$env/static/private' {
	export const SHELL: string;
	export const npm_command: string;
	export const SESSION_MANAGER: string;
	export const QT_ACCESSIBILITY: string;
	export const GHOSTTY_BIN_DIR: string;
	export const COLORTERM: string;
	export const LESS: string;
	export const NVM_INC: string;
	export const HISTCONTROL: string;
	export const XDG_MENU_PREFIX: string;
	export const TERM_PROGRAM_VERSION: string;
	export const GNOME_DESKTOP_SESSION_ID: string;
	export const TMUX: string;
	export const NODE: string;
	export const P4CONFIG: string;
	export const SSH_AUTH_SOCK: string;
	export const GEMINI_API_KEY: string;
	export const MEMORY_PRESSURE_WRITE: string;
	export const TMUX_PLUGIN_MANAGER_PATH: string;
	export const npm_config_local_prefix: string;
	export const DESKTOP_SESSION: string;
	export const GPG_TTY: string;
	export const EDITOR: string;
	export const GTK_MODULES: string;
	export const PWD: string;
	export const RSYNC_RSH: string;
	export const LOGNAME: string;
	export const XDG_SESSION_DESKTOP: string;
	export const XDG_SESSION_TYPE: string;
	export const GPG_AGENT_INFO: string;
	export const SYSTEMD_EXEC_PID: string;
	export const _: string;
	export const XAUTHORITY: string;
	export const TERMINAL: string;
	export const P4MERGE: string;
	export const GJS_DEBUG_TOPICS: string;
	export const GDM_LANG: string;
	export const GHOSTTY_SHELL_FEATURES: string;
	export const HOME: string;
	export const USERNAME: string;
	export const LANG: string;
	export const XDG_CURRENT_DESKTOP: string;
	export const npm_package_version: string;
	export const MEMORY_PRESSURE_WATCH: string;
	export const WAYLAND_DISPLAY: string;
	export const GLINUX_MOTD: string;
	export const PROMPT_COMMAND: string;
	export const INVOCATION_ID: string;
	export const MANAGERPID: string;
	export const BAT_THEME: string;
	export const npm_lifecycle_script: string;
	export const GJS_DEBUG_OUTPUT: string;
	export const ZVM_INSTALL: string;
	export const NVM_DIR: string;
	export const GNOME_SETUP_DISPLAY: string;
	export const GHOSTTY_RESOURCES_DIR: string;
	export const LESSCLOSE: string;
	export const XDG_SESSION_CLASS: string;
	export const PYTHONPATH: string;
	export const TERM: string;
	export const TERMINFO: string;
	export const npm_package_name: string;
	export const LESSOPEN: string;
	export const USER: string;
	export const TMUX_PANE: string;
	export const DISPLAY: string;
	export const npm_lifecycle_event: string;
	export const SHLVL: string;
	export const NVM_CD_FLAGS: string;
	export const PARINIT: string;
	export const GOOGLE_AUTH_WEBAUTHN_PLUGIN: string;
	export const CVS_RSH: string;
	export const npm_config_user_agent: string;
	export const npm_execpath: string;
	export const XDG_RUNTIME_DIR: string;
	export const npm_package_json: string;
	export const BUN_INSTALL: string;
	export const JOURNAL_STREAM: string;
	export const XDG_DATA_DIRS: string;
	export const PATH: string;
	export const GDMSESSION: string;
	export const DBUS_SESSION_BUS_ADDRESS: string;
	export const FZF_DEFAULT_OPTS: string;
	export const NVM_BIN: string;
	export const GIO_LAUNCHED_DESKTOP_FILE_PID: string;
	export const npm_node_execpath: string;
	export const GIO_LAUNCHED_DESKTOP_FILE: string;
	export const TERM_PROGRAM: string;
	export const NODE_ENV: string;
}

/**
 * Similar to [`$env/static/private`](https://svelte.dev/docs/kit/$env-static-private), except that it only includes environment variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`), and can therefore safely be exposed to client-side code.
 * 
 * Values are replaced statically at build time.
 * 
 * ```ts
 * import { PUBLIC_BASE_URL } from '$env/static/public';
 * ```
 */
declare module '$env/static/public' {
	
}

/**
 * This module provides access to runtime environment variables, as defined by the platform you're running on. For example if you're using [`adapter-node`](https://github.com/sveltejs/kit/tree/main/packages/adapter-node) (or running [`vite preview`](https://svelte.dev/docs/kit/cli)), this is equivalent to `process.env`. This module only includes variables that _do not_ begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) _and do_ start with [`config.kit.env.privatePrefix`](https://svelte.dev/docs/kit/configuration#env) (if configured).
 * 
 * This module cannot be imported into client-side code.
 * 
 * ```ts
 * import { env } from '$env/dynamic/private';
 * console.log(env.DEPLOYMENT_SPECIFIC_VARIABLE);
 * ```
 * 
 * > [!NOTE] In `dev`, `$env/dynamic` always includes environment variables from `.env`. In `prod`, this behavior will depend on your adapter.
 */
declare module '$env/dynamic/private' {
	export const env: {
		SHELL: string;
		npm_command: string;
		SESSION_MANAGER: string;
		QT_ACCESSIBILITY: string;
		GHOSTTY_BIN_DIR: string;
		COLORTERM: string;
		LESS: string;
		NVM_INC: string;
		HISTCONTROL: string;
		XDG_MENU_PREFIX: string;
		TERM_PROGRAM_VERSION: string;
		GNOME_DESKTOP_SESSION_ID: string;
		TMUX: string;
		NODE: string;
		P4CONFIG: string;
		SSH_AUTH_SOCK: string;
		GEMINI_API_KEY: string;
		MEMORY_PRESSURE_WRITE: string;
		TMUX_PLUGIN_MANAGER_PATH: string;
		npm_config_local_prefix: string;
		DESKTOP_SESSION: string;
		GPG_TTY: string;
		EDITOR: string;
		GTK_MODULES: string;
		PWD: string;
		RSYNC_RSH: string;
		LOGNAME: string;
		XDG_SESSION_DESKTOP: string;
		XDG_SESSION_TYPE: string;
		GPG_AGENT_INFO: string;
		SYSTEMD_EXEC_PID: string;
		_: string;
		XAUTHORITY: string;
		TERMINAL: string;
		P4MERGE: string;
		GJS_DEBUG_TOPICS: string;
		GDM_LANG: string;
		GHOSTTY_SHELL_FEATURES: string;
		HOME: string;
		USERNAME: string;
		LANG: string;
		XDG_CURRENT_DESKTOP: string;
		npm_package_version: string;
		MEMORY_PRESSURE_WATCH: string;
		WAYLAND_DISPLAY: string;
		GLINUX_MOTD: string;
		PROMPT_COMMAND: string;
		INVOCATION_ID: string;
		MANAGERPID: string;
		BAT_THEME: string;
		npm_lifecycle_script: string;
		GJS_DEBUG_OUTPUT: string;
		ZVM_INSTALL: string;
		NVM_DIR: string;
		GNOME_SETUP_DISPLAY: string;
		GHOSTTY_RESOURCES_DIR: string;
		LESSCLOSE: string;
		XDG_SESSION_CLASS: string;
		PYTHONPATH: string;
		TERM: string;
		TERMINFO: string;
		npm_package_name: string;
		LESSOPEN: string;
		USER: string;
		TMUX_PANE: string;
		DISPLAY: string;
		npm_lifecycle_event: string;
		SHLVL: string;
		NVM_CD_FLAGS: string;
		PARINIT: string;
		GOOGLE_AUTH_WEBAUTHN_PLUGIN: string;
		CVS_RSH: string;
		npm_config_user_agent: string;
		npm_execpath: string;
		XDG_RUNTIME_DIR: string;
		npm_package_json: string;
		BUN_INSTALL: string;
		JOURNAL_STREAM: string;
		XDG_DATA_DIRS: string;
		PATH: string;
		GDMSESSION: string;
		DBUS_SESSION_BUS_ADDRESS: string;
		FZF_DEFAULT_OPTS: string;
		NVM_BIN: string;
		GIO_LAUNCHED_DESKTOP_FILE_PID: string;
		npm_node_execpath: string;
		GIO_LAUNCHED_DESKTOP_FILE: string;
		TERM_PROGRAM: string;
		NODE_ENV: string;
		[key: `PUBLIC_${string}`]: undefined;
		[key: `${string}`]: string | undefined;
	}
}

/**
 * Similar to [`$env/dynamic/private`](https://svelte.dev/docs/kit/$env-dynamic-private), but only includes variables that begin with [`config.kit.env.publicPrefix`](https://svelte.dev/docs/kit/configuration#env) (which defaults to `PUBLIC_`), and can therefore safely be exposed to client-side code.
 * 
 * Note that public dynamic environment variables must all be sent from the server to the client, causing larger network requests — when possible, use `$env/static/public` instead.
 * 
 * ```ts
 * import { env } from '$env/dynamic/public';
 * console.log(env.PUBLIC_DEPLOYMENT_SPECIFIC_VARIABLE);
 * ```
 */
declare module '$env/dynamic/public' {
	export const env: {
		[key: `PUBLIC_${string}`]: string | undefined;
	}
}
