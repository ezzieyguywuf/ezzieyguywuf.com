<script lang="ts">
  import { browser } from "$app/environment";

  let count = $state(0);

  $effect(() => {
    if (browser) {
      // always write changes to localStorage
      localStorage.setItem("count", String(count));

      // update if underlying storage changes
      const handleStorageChange = (event: StorageEvent) => {
        if (event.key === "count") {
          count = parseInt(event.newValue || "0", 10);
        }
      };
      window.addEventListener("storage", handleStorageChange);

      // remove handler on cleanup
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

<button onclick={increment}>
  count is {count}
</button>

<button onclick={reset}> Reset </button>

<style>
  button + button {
    margin-left: 0.5em;
  }
</style>
