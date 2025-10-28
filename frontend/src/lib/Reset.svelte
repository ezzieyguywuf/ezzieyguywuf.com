<script lang="ts">
  let { on_reset = () => {} } = $props();

  const DURATION_MS = 1000;

  let press_progress = $state(0);
  let is_pressing = $state(false);
  let animation_frame_id: number;
  let start_time: number;

  $effect(() => {
    // This effect returns a cleanup function that Svelte will run when the component is destroyed.
    return () => {
      cancelAnimationFrame(animation_frame_id);
    };
  });

  const frame = (timestamp: number) => {
    if (!start_time) {
      start_time = timestamp;
    }

    const elapsed = timestamp - start_time;
    press_progress = (elapsed / DURATION_MS) * 100;

    if (elapsed < DURATION_MS) {
      animation_frame_id = requestAnimationFrame(frame);
    } else {
      press_progress = 0;
      on_reset();
    }
  };

  const handle_pointerdown = () => {
    is_pressing = true;
    start_time = 0; // Reset start time
    animation_frame_id = requestAnimationFrame(frame);
  };

  const stop_animation = () => {
    is_pressing = false;
    cancelAnimationFrame(animation_frame_id);
    press_progress = 0;
  };
</script>

<button
  class="reset-button"
  class:pressing={is_pressing}
  onpointerdown={handle_pointerdown}
  onpointerup={stop_animation}
  onpointerleave={stop_animation}
  style="--progress: {press_progress}%"
>
  Reset
</button>

<style>
  .reset-button {
    user-select: none;
    -webkit-user-select: none; /* Safari */
  }
  .reset-button.pressing {
    background-image: linear-gradient(
      to right,
      #646cff 0%,
      #646cff var(--progress),
      transparent var(--progress),
      transparent 100%
    );
    /* Explicitly define the transition for the background animation */
    transition: background-image 0.1s linear;
  }
</style>
