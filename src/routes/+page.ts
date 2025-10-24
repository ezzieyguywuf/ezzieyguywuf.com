// This file disables Server-Side Rendering for the homepage.
// The page will be rendered entirely on the client-side,
// which is the best way to handle components that rely
// heavily on browser-only APIs like localStorage.

export const ssr = false;
