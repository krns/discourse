# frozen_string_literal: true

RSpec.describe "Editing sidebar tags navigation", type: :system do
  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group).tap { |g| g.add(user) } }
  fab!(:tag1) { Fabricate(:tag, name: "tag").tap { |tag| Fabricate.times(3, :topic, tags: [tag]) } }

  fab!(:tag2) do
    Fabricate(:tag, name: "tag2").tap { |tag| Fabricate.times(2, :topic, tags: [tag]) }
  end

  fab!(:tag3) do
    Fabricate(:tag, name: "tag3").tap { |tag| Fabricate.times(1, :topic, tags: [tag]) }
  end

  # This tag should not be displayed in the modal as it has not been used in a topic
  fab!(:tag4) { Fabricate(:tag, name: "tag4") }

  let(:sidebar) { PageObjects::Components::Sidebar.new }

  before do
    SiteSetting.new_edit_sidebar_categories_tags_interface_groups = group.name
    sign_in(user)
  end

  it "allows a user to edit the sidebar categories navigation" do
    visit "/latest"

    expect(sidebar).to have_tags_section
    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_section_link(tag2.name)
    expect(sidebar).to have_section_link(tag3.name)

    modal = sidebar.click_edit_tags_button

    expect(modal).to have_right_title(I18n.t("js.sidebar.tags_form_modal.title"))
    expect(modal).to have_tag_checkboxes([tag1, tag2, tag3])

    modal.toggle_tag_checkbox(tag1).toggle_tag_checkbox(tag2).save

    expect(modal).to be_closed
    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_section_link(tag2.name)
    expect(sidebar).to have_no_section_link(tag3.name)

    visit "/latest"

    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_section_link(tag2.name)
    expect(sidebar).to have_no_section_link(tag3.name)

    modal = sidebar.click_edit_tags_button
    modal.toggle_tag_checkbox(tag2).save

    expect(modal).to be_closed

    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_no_section_link(tag2.name)
    expect(sidebar).to have_no_section_link(tag3.name)
  end

  it "allows a user to filter the tags in the modal by the tag's name" do
    visit "/latest"

    expect(sidebar).to have_tags_section

    modal = sidebar.click_edit_tags_button

    modal.filter("tag")

    expect(modal).to have_tag_checkboxes([tag1, tag2, tag3])

    modal.filter("tag2")

    expect(modal).to have_tag_checkboxes([tag2])

    modal.filter("someinvalidterm")

    expect(modal).to have_no_tag_checkboxes
  end

  it "allows a user to deselect all tags in the modal which will display the site's top tags" do
    Fabricate(:tag_sidebar_section_link, user: user, linkable: tag1)

    visit "/latest"

    expect(sidebar).to have_tags_section
    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_no_section_link(tag2.name)
    expect(sidebar).to have_no_section_link(tag3.name)

    modal = sidebar.click_edit_tags_button
    modal.deselect_all.save

    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_section_link(tag2.name)
    expect(sidebar).to have_section_link(tag3.name)
  end

  it "allows a user to reset to the default navigation menu tags site setting" do
    Fabricate(:tag_sidebar_section_link, user: user, linkable: tag1)

    SiteSetting.default_navigation_menu_tags = "#{tag2.name}|#{tag3.name}"

    visit "/latest"

    expect(sidebar).to have_tags_section
    expect(sidebar).to have_section_link(tag1.name)
    expect(sidebar).to have_no_section_link(tag2.name)
    expect(sidebar).to have_no_section_link(tag3.name)

    modal = sidebar.click_edit_tags_button
    modal.click_reset_to_defaults_button.save

    expect(modal).to be_closed
    expect(sidebar).to have_no_section_link(tag1.name)
    expect(sidebar).to have_section_link(tag2.name)
    expect(sidebar).to have_section_link(tag3.name)
  end
end
