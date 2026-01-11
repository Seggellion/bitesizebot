module ThemeHelper
  def current_theme
    Rails.application.config.active_theme || "Dusk"
  end

  def render_theme_partial(path, fallback: nil)
    if lookup_context.exists?(path, [], true)
      render path
    else
      fallback || content_tag(
        :div,
        "missing section code: #{path}",
        class: "missing-section"
      )
    end
  end
end
