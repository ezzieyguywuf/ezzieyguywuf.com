<script lang="ts">
	import Counter from '$lib/Counter.svelte';
	import Reset from '$lib/Reset.svelte';

	let reset_latch = $state(false);
</script>

<div class="button-group" oncontextmenu={(e) => e.preventDefault()} role="group">
	<Counter do_reset={reset_latch} on_reset={() => (reset_latch = false)} />
	<Reset on_reset={() => (reset_latch = true)} />
</div>

<style>
	.button-group {
		display: flex;
		flex-wrap: wrap;
		gap: 0.5em;
		justify-content: center;
	}
	@media (max-width: 600px) {
		.button-group {
			flex-direction: column;
			align-items: center;
		}
	}
</style>
