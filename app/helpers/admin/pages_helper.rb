# app/helpers/admin/pages_helper.rb
module Admin::PagesHelper
  def template_options
    theme_templates_path = Rails.root.join('app', 'themes', current_theme, 'views', 'pages')
    Dir.entries(theme_templates_path)
       .select { |f| f.start_with?('page-') && f.end_with?('.html.erb') }
       .map { |f| [f.chomp('.html.erb').sub('page-', ''), f.chomp('.html.erb').sub('page-', '')] }
  rescue Errno::ENOENT
    []
  end
end
