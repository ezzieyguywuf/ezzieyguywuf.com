<script lang="ts">
  import { counter, COUNTER_KEY } from "./counter";

  let { do_reset = false, on_reset = () => {} } = $props();

  let count = $state(counter.get());

  const increment = () => {
    count++;
    counter.set(count);
  };

  const reset = () => {
    count = 0;
    counter.set(count);
  };

  // This effect "listens" for the parent to set the do_reset latch
  $effect(() => {
    if (do_reset) {
      reset();
      on_reset(); // Signal back to the parent that the reset is done
    }
  });

  // This effect listens for changes from other tabs
  $effect(() => {
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === COUNTER_KEY) {
        count = parseInt(event.newValue || "0", 10);
      }
    };
    window.addEventListener("storage", handleStorageChange);

    return () => {
      window.removeEventListener("storage", handleStorageChange);
    };
  });
</script>

<button onclick={increment}>
  {count.toLocaleString()} clicks!
</button>
