import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("topic-timer-to-top", (api) => {
  // ✅ Show timer only if top or both is selected
  if (["top", "both"].includes(settings.display_location)) {
    api.decorateWidget("topic-above-posts:after", (helper) => {
      const topic = helper.getModel();

      // If there's a timer, render the default component
      if (topic?.topic_timer) {
        return helper.attach("topic-timer-info", {});
      }
    });
  }

  // ✅ Remove bottom version if top-only
  if (settings.display_location === "top") {
    api.modifyClass("component:topic-timer-info", {
      didInsertElement() {
        if (!this.element.closest(".topic-above-posts")) {
          this.element.remove();
        }
      },
    });
  }

  // ✅ DOM patch to override text and parent category
  if (settings.link_to_parent_category || settings.topic_label_override) {
    api.onPageChange(() => {
      requestAnimationFrame(() => {
        document.querySelectorAll(".topic-timer-info").forEach((el) => {
          const text = el.textContent?.trim();
          if (!text?.includes("will be published to")) return;

          // Override "This topic"
          if (settings.topic_label_override) {
            el.innerHTML = el.innerHTML.replace(
              /\bThis topic\b/i,
              `This ${settings.topic_label_override}`
            );
          }

          // Swap to parent category
          if (settings.link_to_parent_category) {
            const link = el.querySelector("a[href*='/c/']");
            if (!link) return;

            const href = link.getAttribute("href");
            const match = href.match(/\/c\/(.+)\/(\d+)/);
            if (!match) return;

            const slug = match[1].split("/").pop();
            const id = parseInt(match[2], 10);
            const cats = api.container.lookup("site:main").categories;
            const cat = cats.find((c) => c.id === id && c.slug === slug);
            if (!cat?.parent_category_id) return;

            const parent = cats.find((c) => c.id === cat.parent_category_id);
            if (!parent) return;

            link.textContent = `#${parent.slug}`;
            link.setAttribute("href", `/c/${parent.slug}/${parent.id}`);
          }
        });
      });
    });
  }
});
