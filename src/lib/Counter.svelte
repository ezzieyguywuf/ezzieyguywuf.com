<script lang="ts">
  let count = $state(parseInt(localStorage.getItem("count") || "0", 10));

  // Save to localStorage any time the value changes
  $effect(() => {
    localStorage.setItem("count", String(count));
  });

  // Update count if localStorage value changed
  $effect(() => {
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === "count") {
        count = parseInt(event.newValue || "0", 10);
      }
    };
    window.addEventListener("storage", handleStorageChange);

    // remove the listener on cleanup
    return () => {
      window.removeEventListener("storage", handleStorageChange);
    };
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
