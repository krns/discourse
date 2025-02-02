import { cached } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import { action } from "@ember/object";

import SidebarCommonTagsSection from "discourse/components/sidebar/common/tags-section";
import TagSectionLink from "discourse/lib/sidebar/user/tags-section/tag-section-link";
import PMTagSectionLink from "discourse/lib/sidebar/user/tags-section/pm-tag-section-link";
import { hasDefaultSidebarTags } from "discourse/lib/sidebar/helpers";
import showModal from "discourse/lib/show-modal";

export default class SidebarUserTagsSection extends SidebarCommonTagsSection {
  @service router;
  @service topicTrackingState;
  @service pmTopicTrackingState;
  @service currentUser;
  @service siteSettings;

  constructor() {
    super(...arguments);

    this.callbackId = this.topicTrackingState.onStateChange(() => {
      this.sectionLinks.forEach((sectionLink) => {
        if (sectionLink.refreshCounts) {
          sectionLink.refreshCounts();
        }
      });
    });
  }

  willDestroy() {
    this.topicTrackingState.offStateChange(this.callbackId);
  }

  @cached
  get sectionLinks() {
    const links = [];

    let tags;

    if (this.currentUser.sidebarTags.length > 0) {
      tags = this.currentUser.sidebarTags;
    } else {
      tags = this.topSiteTags.map((tagName) => {
        return {
          name: tagName,
          pm_only: false,
        };
      });
    }

    for (const tag of tags) {
      if (tag.pm_only) {
        links.push(
          new PMTagSectionLink({
            tagName: tag.name,
            currentUser: this.currentUser,
          })
        );
      } else {
        links.push(
          new TagSectionLink({
            tagName: tag.name,
            topicTrackingState: this.topicTrackingState,
            currentUser: this.currentUser,
          })
        );
      }
    }

    return links;
  }

  get shouldDisplayDefaultConfig() {
    return this.currentUser.admin && !this.hasDefaultSidebarTags;
  }

  get hasDefaultSidebarTags() {
    return hasDefaultSidebarTags(this.siteSettings);
  }

  @action
  editTracked() {
    if (
      this.currentUser.new_edit_sidebar_categories_tags_interface_groups_enabled
    ) {
      showModal("sidebar-tags-form");
    } else {
      this.router.transitionTo("preferences.navigation-menu", this.currentUser);
    }
  }
}
