<script>
  import Counter from "./lib/Counter.svelte";
</script>

<main>
  <img
    class="construction-sign"
    src="/under-construction.svg"
    alt="Under Construction"
  />
  <h1>Under Construction</h1>

  <!-- <p>This site is under construction</p> -->
  <p>Last updated October 22nd, 2025</p>
  <p>
    Check back soon for (maybe) more. In the meantime, enjoy this button that
    tells you how many times it's been clicked.
  </p>

  <div class="card">
    <Counter />
  </div>
</main>

<style>
  .construction-sign {
    display: block;
    margin: 0 auto 2rem auto;
    width: 50%;
    max-width: 400px;
  }
</style>
