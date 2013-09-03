module ApplicationHelper

  def theme_tags_links(theme)
    theme.tag_list.map { |t| link_to( t, tag_path(t) )}.join(', ').html_safe
  end

end
