<script lang="ts">
  import { browser } from "$app/environment";

  let initial_count = 0;
  if (browser) {
    initial_count = parseInt(localStorage.getItem("count") || "0", 10);
  }
  let count = $state(initial_count);

  $effect(() => {
    if (browser) {
      // This effect depends on `count`, so it will re-run whenever `count` is modified.
      localStorage.setItem("count", String(count));
    }
  });

  $effect(() => {
    if (browser) {
      // This effect has no reactive dependencies, so it only runs once on load
      count = parseInt(localStorage.getItem("count") || "0", 10);

      // update Count if underlying storage changes
      const handleStorageChange = (event: StorageEvent) => {
        if (event.key === "count") {
          count = parseInt(event.newValue || "0", 10);
        }
      };
      window.addEventListener("storage", handleStorageChange);

      // cleanup
      return () => {
        window.removeEventListener("storage", handleStorageChange);
      };
    }
  });

  const increment = () => {
    count += 1;
  };

  const reset = () => {
    count = 0;
  };
</script>

<div class="button-group">
  <button onclick={increment}>
    count is {count}
  </button>

  <button onclick={reset}> Reset </button>
</div>

<style>
  .button-group {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5em;
    justify-content: center;
  }
</style>
