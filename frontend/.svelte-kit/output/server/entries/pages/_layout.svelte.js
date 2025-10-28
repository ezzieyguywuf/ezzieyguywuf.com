import { w as head, x as attr } from "../../chunks/index.js";
const favicon = "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTAwIiBoZWlnaHQ9IjEwMCIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgPHRleHQKICAgIHg9IjAiCiAgICB5PSI4MCIKICAgIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIKICAgIGZvbnQtc2l6ZT0iOTAiCiAgICBmb250LXdlaWdodD0iYm9sZCIKICAgIGZpbGw9IiMwMDAwMDAiCiAgPgogICAgZQogIDwvdGV4dD4KICA8dGV4dAogICAgeD0iMzUiCiAgICB5PSIxMDAiCiAgICBmb250LWZhbWlseT0iQXJpYWwsIHNhbnMtc2VyaWYiCiAgICBmb250LXNpemU9IjkwIgogICAgZm9udC13ZWlnaHQ9ImJvbGQiCiAgICBmaWxsPSIjMDAwMDAwIgogID4KICAgIHoKICA8L3RleHQ+Cjwvc3ZnPg==";
function _layout($$renderer, $$props) {
  let { children } = $$props;
  head($$renderer, ($$renderer2) => {
    $$renderer2.push(`<link rel="icon"${attr("href", favicon)}/>`);
  });
  children?.($$renderer);
  $$renderer.push(`<!---->`);
}
export {
  _layout as default
};
