// This is a simple service for interacting with the count in localStorage.
// It has no Svelte-specific code and can be used anywhere.

export const COUNTER_KEY = 'count';

export const counter = {
	get: (): number => {
		return parseInt(localStorage.getItem(COUNTER_KEY) || '0', 10);
	},
	set: (value: number): void => {
		localStorage.setItem(COUNTER_KEY, String(value));
	}
};
