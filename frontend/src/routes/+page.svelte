<script lang="ts">
	import CounterWidget from '$lib/CounterWidget.svelte';
  import StreamingCounter from '$lib/StreamingCounter.svelte';

	const changelog = [
    {
      date: '2025-11-03',
      changes: [
        'Launched Community Counter!',
        'Moved frontend off of github pages to my gaming rig',
        'Started hosting zig backend on my gaming rig',
      ]
    },
		{
			date: '2025-10-23',
			changes: [
				'Disable server-side rendering',
				'Fix persistent clicks after sveltkit migration',
				'Made buttons bigger.',
				'Migrated to sveltekit.',
				'Added persistent, multi-tab counter.',
				'Converted project to TypeScript.',
				'Migrated to SvelteKit.'
			]
		},
		{
			date: '2025-10-22',
			changes: ['Initial deployment to GitHub Pages.']
		}
	];
</script>

<svelte:head>
	<h1>Wolfgang E. Sanyer's Website</h1>
  <meta name="description" content="A self-hosted personal site. Hosts a counter game that everyone can participate in together."/>
</svelte:head>

<main>

	<div class="card">
    <h2>Live Community Counter</h2>
		<p>This is shared between anyone who visits the site: that's why there's no
    reset. Let's see how high it will go!</p>
		<StreamingCounter />
	</div>
	<div class="card">
    <h2>Local "Just You" Counter</h2>
		<p>This button is local to your browser. You can reset whenever you want, otherwise the count will persist until or if you clear your browser cookies</p>
		<CounterWidget />
	</div>

	<h2>Changelog</h2>
	{#each changelog as entry}
		<h3>{entry.date}</h3>
		<ul>
			{#each entry.changes as change}
				<li>{change}</li>
			{/each}
		</ul>
	{/each}

	<h2>Coming Soon</h2>
	<ul>
    <li>Maybe leaderboard? (who's clicked the most!)</li>
    <li>Maybe live tracking of who's clicking now!</li>
    <li>Maybe a map showing who's clicking from where!</li>
		<li>Maybe a blog?</li>
		<li>More interesting things to click.</li>
		<li>Maybe a login (to save your clicks!)</li>
	</ul>

	<p class="compact">Last updated October 23rd, 2025</p>
</main>

<style>
	.compact {
		margin-top: 0em;
		margin-bottom: 0em;
	}
	ul {
		list-style: none;
		padding-left: 1.75rem; /* Indent the whole list */
		margin-bottom: 1.5rem;
		text-align: left;
	}
	h1,
	h2,
	h3 {
		text-align: left;
	}
	li {
		position: relative;
		/* padding-left is no longer needed here */
		margin-bottom: 0.5rem;
	}
	li::before {
		content: '→'; /* Custom bullet */
		position: absolute;
		left: -1.75rem; /* Position the bullet outside the text flow */
		top: 0;
		color: #646cff;
		font-weight: bold;
	}
</style>

