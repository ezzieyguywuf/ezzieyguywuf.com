export const manifest = (() => {
function __memo(fn) {
	let value;
	return () => value ??= (value = fn());
}

return {
	appDir: "_app",
	appPath: "_app",
	assets: new Set(["CNAME","under-construction.svg"]),
	mimeTypes: {".svg":"image/svg+xml"},
	_: {
		client: {start:"_app/immutable/entry/start.C7cjMfAc.js",app:"_app/immutable/entry/app.VOfCAw0G.js",imports:["_app/immutable/entry/start.C7cjMfAc.js","_app/immutable/chunks/ChxuOyDi.js","_app/immutable/chunks/DWkpLyF_.js","_app/immutable/chunks/ROgFvJsU.js","_app/immutable/chunks/Boh57UKE.js","_app/immutable/chunks/BCBPs9jg.js","_app/immutable/entry/app.VOfCAw0G.js","_app/immutable/chunks/ROgFvJsU.js","_app/immutable/chunks/Boh57UKE.js","_app/immutable/chunks/DsnmJJEf.js","_app/immutable/chunks/DWkpLyF_.js","_app/immutable/chunks/BCBPs9jg.js"],stylesheets:[],fonts:[],uses_env_dynamic_public:false},
		nodes: [
			__memo(() => import('./nodes/0.js')),
			__memo(() => import('./nodes/1.js')),
			__memo(() => import('./nodes/2.js'))
		],
		remotes: {
			
		},
		routes: [
			{
				id: "/",
				pattern: /^\/$/,
				params: [],
				page: { layouts: [0,], errors: [1,], leaf: 2 },
				endpoint: null
			}
		],
		prerendered_routes: new Set([]),
		matchers: async () => {
			
			return {  };
		},
		server_assets: {}
	}
}
})();
