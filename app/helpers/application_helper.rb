module ApplicationHelper
  def meta_title
    if content_for?(:meta_title)
      content_for(:meta_title)
    elsif @service.is_a?(ActiveRecord::Relation)
      "List of Services" # Adjust this as needed for other models
    elsif @service&.title.present?
      @service.title
    elsif @page&.title.present?
      @page.title
    elsif @post&.title.present?
      @post.title
    else
      Setting.get('site-title') || "Default Title"
    end
  end
  
  def canonical_url
    request.original_url
 end  

 def meta_description
  if content_for?(:meta_description)
    content_for(:meta_description)
  elsif @service.is_a?(ActiveRecord::Relation)
    "A comprehensive list of our services." # Adjust this as needed for your context
  elsif @service&.meta_description.present?
    @service.meta_description
  elsif @page&.meta_description.present?
    @page.meta_description
  elsif @post&.meta_description.present?
    @post.meta_description
  else    
    extract_description(@service&.content || @page&.content || @posts&.first&.content) || Setting.get('website-description')
  end
end 

  def unread_messages_count
    ContactMessage.unread_count
  end

  def favicon_url
    favicon = Setting.get('favicon')
    favicon.presence || asset_path('favicon.ico')
  end
  
  def twitter_card
    "summary_large_image" # Default to summary with a large image
  end

  def twitter_title
    og_title
  end

  def twitter_description
    og_description
  end

  def twitter_image
    og_image
  end

  def og_type
    if defined?(@post)
      "article"
    elsif defined?(@product)
      "product"
    else
      "website"
    end
  end

  def og_url
    request.original_url
  end

def og_image
  if content_for?(:og_image)
    return content_for(:og_image)
  end

  seo_image = url_for(Setting.get('seo-image'))

  # For collection pages like Services#index
  if @service.is_a?(ActiveRecord::Relation)
    return seo_image
  end

  # Handle Page (has_many_attached :images)
  page_image =
    if @page.respond_to?(:images)
      @page.images.first
    elsif @page.respond_to?(:image)
      @page.image
    end

  # Handle Service (has_many_attached :images)
  service_image =
    if @service.respond_to?(:images)
      @service.images.first
    elsif @service.respond_to?(:image)
      @service.image
    end

  # First embedded rich-text image
  content_image = extract_first_content_image(@page)

  if service_image.present?
    url_for(service_image)
  elsif page_image.present?
    url_for(page_image)
  elsif content_image.present?
    url_for(content_image)
  else
    seo_image
  end
end


  def og_description
    meta_description
  end

  def og_title
    meta_title
  end

  def meta_keywords
    if content_for?(:meta_keywords)
      content_for(:meta_keywords)
    elsif @service.is_a?(ActiveRecord::Relation)
      "services, list, offerings" # Adjust this as needed for your context
    elsif @service&.meta_keywords.present?
      @service.meta_keywords
    elsif @page&.meta_keywords.present?
      @page.meta_keywords
    elsif @post&.meta_keywords.present?
      @post.meta_keywords
    else
      extract_keywords(@service&.content || @page&.content) || @post&.content || Setting.get('default-keywords')
    end
  end
      
  def sub_menu_open_controllers
    %w[home acct_mgmt content pages economy]
  end

def breadcrumbs_for_current_page
  current_slug = current_page_slug

  all_items = @sidebar_menu_items || MenuItem.roots.includes(:children)

  active_item =
    all_items.flat_map { |mi| [mi, *mi.children] }.find do |mi|
      normalize_slug(mi.url) == current_slug
    end

    return [] unless active_item

  # --- CONDITION 1: If it's Home or within Home, hide breadcrumbs entirely ---
  if active_item.url == '/' || active_item.parent&.url == '/'
    return []
  end

  # --- CONDITION 2: If it's a child page of some other parent, show full path ---
  if active_item.parent
    [active_item.parent, active_item]

  # --- CONDITION 3: If it's a top-level page (not home), show itself ---
  else
    [active_item]
  end
end



  def normalize_slug(url)
    u = url.to_s.strip
    return 'home' if u.blank? || u == '/'
    u.sub(/^\//, '').parameterize.underscore
  end

 def current_page_slug
    if controller.controller_name == 'pages'
      normalize_slug(params[:slug] || 'home')
    elsif controller.controller_name == 'services' && @service&.respond_to?(:slug)
      normalize_slug(@service.slug)
    elsif controller.controller_name == 'posts' && @post&.respond_to?(:slug)
      normalize_slug(@post.slug)
    elsif controller.controller_name == 'products' && @product&.respond_to?(:slug)
      normalize_slug(@product.slug)
    else
      controller.controller_name.parameterize.underscore
    end
  end

    # --- Active branch resolution ----------------------------------------------

  # Top-level item that corresponds to the current page context,
  # either by direct match on its own URL, or because one of its children matches.
  def find_active_top_item(menu_items)
    cur = current_page_slug

    # 1) exact top-level match
    menu_items.find { |mi| normalize_slug(mi.url) == cur } ||
      # 2) parent whose child matches
      menu_items.find { |mi| mi.children.any? { |c| normalize_slug(c.url) == cur } }
  end
  
  def sub_menu_open?(menu_item)
    menu_slug  = normalize_slug(menu_item.url)
    cur_slug   = current_page_slug
    active_top = find_active_top_item(@sidebar_menu_items)

    # Open submenu for the active top-level branch
    return true if active_top && normalize_slug(active_top.url) == menu_slug

    # Or if the current page is one of this item's children
    return true if menu_item.children.any? { |c| normalize_slug(c.url) == cur_slug }

    # Fallback: open Home submenu when there is no active branch
    # or when the active branch has no children (i.e., no siblings to show)
    if menu_slug == 'home'
      return true if active_top.nil? || active_top.children.blank?
    end

    false
  end




  private


def extract_first_content_image(page)
  return nil unless page&.content.present?

  page.content.embeds.find do |embed|
    embed.respond_to?(:blob) && embed.blob.image?
  end
end


  def extract_description(content)
    content.to_plain_text.truncate(160) if content.present?
  end

  def extract_keywords(content)
    return "" unless content.present?
    # Extract keywords from the content (simple implementation)
    keywords = strip_tags(content).split.uniq.take(10).join(", ")
    keywords.presence || "default, keywords, for, your, website"
  end

  def page_url(page)
    "/#{page.slug}"
  end
end
