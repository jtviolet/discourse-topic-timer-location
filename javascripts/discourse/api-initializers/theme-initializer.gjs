import { apiInitializer } from "discourse/lib/api";
import TopicTimerInfo from "discourse/components/topic-timer-info";

export default apiInitializer("topic-timer-to-top", (api) => {
  const displayLocation = settings.display_location;
  const renderTopTimer = displayLocation === "Top" || displayLocation === "Both";
  const removeBottomTimer = displayLocation === "Top";

  if (renderTopTimer) {
    api.renderInOutlet("topic-above-posts", (outletArgs) => {
      const topic = outletArgs?.model;
      const slug = topic?.category?.slug;

      // ✅ If slugs are defined, only render if it's included
      if (
        settings.enabled_category_slugs?.length &&
        (!slug || !settings.enabled_category_slugs.includes(slug))
      ) {
        return;
      }

      if (!topic?.topic_timer) return;

      return (
        <div class="custom-topic-timer-top">
          <TopicTimerInfo
            @topicClosed={{@outletArgs.model.closed}}
            @statusType={{@outletArgs.model.topic_timer.status_type}}
            @statusUpdate={{@outletArgs.model.topic_status_update}}
            @executeAt={{@outletArgs.model.topic_timer.execute_at}}
            @basedOnLastPost={{@outletArgs.model.topic_timer.based_on_last_post}}
            @durationMinutes={{@outletArgs.model.topic_timer.duration_minutes}}
            @categoryId={{@outletArgs.model.topic_timer.category_id}}
          />
        </div>
      );
    });
  }

  if (removeBottomTimer) {
    api.modifyClass("component:topic-timer-info", {
      pluginId: "topic-timer-to-top",

      didInsertElement() {
        if (!this.element.closest(".custom-topic-timer-top")) {
          this.element.remove();
        }
      },
    });
  }

  if (settings.use_parent_for_link) {
    api.onPageChange(() => {
      requestAnimationFrame(() => {
        const allTimers = document.querySelectorAll(".topic-timer-info");

        allTimers.forEach((el) => {
          const text = el.textContent?.trim();
          if (!text?.includes("will be published to")) return;

          const categoryLink = el.querySelector("a[href*='/c/']");
          if (!categoryLink) return;

          const href = categoryLink.getAttribute("href");
          const match = href.match(/\/c\/(.+)\/(\d+)/);
          if (!match) return;

          const fullSlug = match[1];
          const slug = fullSlug.split("/").pop();
          const id = parseInt(match[2], 10);
          const siteCategories = api.container.lookup("site:main").categories;

          const category = siteCategories.find((cat) => cat.id === id && cat.slug === slug);
          if (!category?.parent_category_id) return;

          const parent = siteCategories.find((cat) => cat.id === category.parent_category_id);
          if (!parent) return;

          // ✅ Only change the text, keep link pointing to child
          categoryLink.textContent = `#${parent.slug}`;
        });
      });
    });
  }
});
