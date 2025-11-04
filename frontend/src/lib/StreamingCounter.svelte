<script lang="ts">
  import { onMount } from "svelte";

  let count: number | string = $state("Loading...");

  async function increment() {
    try {
      const response = await fetch("/api/increment_counter", {
        method: "POST",
      });
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      const data = await response.json();
      count = parseInt(data.totalCount || "-1", 10);
    } catch (error) {
      console.error("Failed to increment counter:", error);
      count = "Error";
    }
  }

  let eventSource: EventSource | null = null;
  function connect() {
    if (eventSource && eventSource.readyState !== EventSource.CLOSED) {
      eventSource.close();
    }

    console.log("Connecting to server for streaming updates...");
    eventSource = new EventSource("/api/listen_count");

    eventSource.onopen = (_) => {
      console.log("Connection to backend complete");
    };

    eventSource.onmessage = (event) => {
      count = parseInt(event.data || "-1", 10);
    };

    eventSource.onerror = (err) => {
      console.error("EventSource failed:", err);
    };
  }

  function handleVisibilityChange() {
    if (document.visibilityState === "visible") {
      console.log("Page is visible, checking connection");

      if (eventSource && eventSource.readyState !== EventSource.CLOSED) {
        console.log("Connection was dead, re-establishing");
        connect();
      } else if (!eventSource) {
        connect();
      }
    }
  }
  onMount(() => {
    async function getInitialCount() {
      console.log("Trying to get initial count");
      try {
        const resp = await fetch("/api/get_count");
        if (!resp.ok) {
          throw new Error("Failed to fetch initial count");
        }
        const data = await resp.json();
        count = parseInt(data.totalCount || "-1", 10);
      } catch (error) {
        console.error(error);
      }
    }
    getInitialCount();

    connect();
    document.addEventListener("visibilitychange", handleVisibilityChange);

    return () => {
      console.log("Closing SSE connection.");
      if (eventSource) {
        eventSource.close();
      }
    };
  });
</script>

<div class="counter-widget">
  <button onclick={increment}>
    {count.toLocaleString()} clicks worldwide!
  </button>
</div>

<style>
</style>
