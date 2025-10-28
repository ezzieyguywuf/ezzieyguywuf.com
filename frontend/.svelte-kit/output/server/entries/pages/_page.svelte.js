import { y as ensure_array_like } from "../../chunks/index.js";
import { e as escape_html } from "../../chunks/context.js";
import "clsx";
function Counter($$renderer, $$props) {
  $$renderer.component(($$renderer2) => {
    let count = 0;
    $$renderer2.push(`<button class="svelte-dfcawr">count is ${escape_html(count)}</button> <button class="svelte-dfcawr">Reset</button>`);
  });
}
function _page($$renderer) {
  const changelog = [
    {
      date: "2025-10-23",
      changes: [
        "Added persistent, multi-tab counter.",
        "Converted project to TypeScript.",
        "Migrated to SvelteKit."
      ]
    },
    {
      date: "2025-10-22",
      changes: ["Initial deployment to GitHub Pages."]
    }
  ];
  $$renderer.push(`<main><h1 class="svelte-1uha8ag">ezzieyguywuf.com</h1> <div class="card"><p>This button tells you how many time's it's been clicked!</p> `);
  Counter($$renderer);
  $$renderer.push(`<!----></div> <h2 class="svelte-1uha8ag">Changelog</h2> <!--[-->`);
  const each_array = ensure_array_like(changelog);
  for (let $$index_1 = 0, $$length = each_array.length; $$index_1 < $$length; $$index_1++) {
    let entry = each_array[$$index_1];
    $$renderer.push(`<h3 class="svelte-1uha8ag">${escape_html(entry.date)}</h3> <ul class="svelte-1uha8ag"><!--[-->`);
    const each_array_1 = ensure_array_like(entry.changes);
    for (let $$index = 0, $$length2 = each_array_1.length; $$index < $$length2; $$index++) {
      let change = each_array_1[$$index];
      $$renderer.push(`<li class="svelte-1uha8ag">${escape_html(change)}</li>`);
    }
    $$renderer.push(`<!--]--></ul>`);
  }
  $$renderer.push(`<!--]--> <h2 class="svelte-1uha8ag">Coming Soon</h2> <ul class="svelte-1uha8ag"><li class="svelte-1uha8ag">Maybe a blog?</li> <li class="svelte-1uha8ag">More interesting things to click.</li> <li class="svelte-1uha8ag">Maybe a login (to save your clicks!)</li></ul> <p class="compact svelte-1uha8ag">Last updated October 23rd, 2025</p></main>`);
}
export {
  _page as default
};
