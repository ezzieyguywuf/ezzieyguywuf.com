<script lang="ts">
  import { onMount } from 'svelte';

  let count = $state('Loading...');

  async function increment(){
    try {
      const response = await fetch('/api/increment_counter', {
        method: 'POST',
      });
      if (!response.ok) {
        throw new Error('Network response was not ok');
      }
      const data = await response.json();
      count = data.totalCount;
    } catch (error) {
      console.error('Failed to increment counter:', error);
      count = 'Error';
    }
  }

  onMount(() => {
    async function getInitialCount() {
      console.log('Trying to get initial count');
      try {
        const resp = await fetch('/api/get_count')
        if (!resp.ok) {
          throw new Error('Failed to fetch initial count');
        }
        const data = await resp.json();
        count = data.totalCount;
      } catch (error) {
        console.error(error);
      }
    }
    getInitialCount();

    console.log('Connecting to server for streaming updates...');
    const eventSource = new EventSource('/api/listen_count');

    eventSource.onmessage = (event) => {
      count = event.data;
    };

    eventSource.onerror = (err) => {
      console.error('EventSource failed:', err);
    };

    return () => {
      console.log('Closing SSE connection.');
      eventSource.close();
    }
  })
</script>

<div class="counter-widget">
  <button onclick={increment}>
    {count.toLocaleString()} clicks worldwide!
  </button>
</div>

<style>
</style>
