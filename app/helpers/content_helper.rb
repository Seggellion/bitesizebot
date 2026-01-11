# app/helpers/posts_helper.rb
module ContentHelper
  # Accepts ActionText (RichText/Content) or a plain String.
  # String input:
  #   - 2+ words: replace first alphabetic char of the first TWO words with dropcap IMG elements.
  #   - 1 word: replace first alphabetic char of the first word (as before).
  #   Returns just the resulting HTML string (no extra wrappers).
  #
  # RichText input:
  #   - Preserves formatting and injects a single dropcap IMG into the first paragraph (as before).
  #
  # Images are resolved as: decorated_letters/letter_<downcased_char>.png
  def dropcap_rich_text(input, image_basename: nil, height_px: 60)
    return "".html_safe if input.blank?

    if input.is_a?(String)
      return dropcap_string_two_words(input, height_px: height_px)
    end

    # ---- RichText / ActionText path (preserve formatting, single dropcap) ----
    html = input.to_s

    unless defined?(Nokogiri)
      # Fallback: simple single-letter prepend (no wrappers)
      return prepend_single_dropcap_to_text(html, image_basename: image_basename, height_px: height_px)
    end

    frag = Nokogiri::HTML::DocumentFragment.parse(html)

    # First <p>, else first element; else wrap all text into a <p>
    first_p = frag.at("p") || frag.children.detect(&:element?)
    unless first_p
      text_only = frag.text
      return html.html_safe if text_only.blank?

      first_p = Nokogiri::XML::Node.new("p", frag)
      first_p.content = text_only
      frag.children.remove
      frag.add_child(first_p)
    end

    # First visible text node
    text_node = first_p.xpath(".//text()").find { |n| n.text =~ /\S/ }
    return frag.to_html.html_safe unless text_node

    text = text_node.text
    i    = text.index(/[[:alpha:]]/u)
    return frag.to_html.html_safe unless i

    first_char = text[i]
    remaining  = text[0...i].to_s + text[(i + 1)..].to_s
    text_node.content = remaining

    # Use provided basename if given; else per-letter default
    filename = image_basename.presence || "letter_#{first_char.downcase}.png"
    image_logical_path = File.join("decorated_letters", filename)

    img_html = image_tag(image_logical_path,
                         class: "dropcap",
                         alt: first_char,
                         "aria-hidden": true,
                         height: height_px)
    sr_html  = content_tag(:span, first_char, class: "sr-only")

    first_p['class'] = [first_p['class'], 'dropcap-paragraph'].compact.join(' ')
    insertion = Nokogiri::HTML::DocumentFragment.parse(img_html + sr_html)
    first_p.children.first&.add_previous_sibling(insertion) || first_p.add_child(insertion)

    frag.to_html.html_safe
  end

  private

  # String path: replace first alphabetic character of up to two words.
  def dropcap_string_two_words(text, height_px:)
    parts = text.split(/(\s+)/) # keep whitespace delimiters
    replaced = 0

    parts.map! do |segment|
      break parts if replaced >= 2 # stop scanning further segments

      if segment =~ /\S/ && segment !~ /\A\s+\z/
        # Non-whitespace "word-like" segment; replace its first alphabetic character
        idx = segment.index(/[[:alpha:]]/u)
        if idx
          first_char = segment[idx]
          img_html   = dropcap_img_for(first_char, height_px: height_px)
          sr_html    = content_tag(:span, first_char, class: "sr-only")

          segment = segment[0...idx].to_s + img_html + sr_html + segment[(idx + 1)..].to_s
          replaced += 1
        end
      end

      segment
    end

    parts.join.html_safe
  end

  # Fallback used when Nokogiri is unavailable for rich text
  def prepend_single_dropcap_to_text(text, image_basename:, height_px:)
    t = text.dup
    idx = t.index(/[[:alpha:]]/u)
    return text.html_safe if idx.nil?

    first_char = t[idx]
    remaining  = t[0...idx].to_s + t[(idx + 1)..].to_s

    filename = image_basename.presence || "letter_#{first_char.downcase}.png"
    image_logical_path = File.join("decorated_letters", filename)

    img_html = image_tag(image_logical_path,
                         class: "dropcap",
                         alt: first_char,
                         "aria-hidden": true,
                         height: height_px)
    sr_html  = content_tag(:span, first_char, class: "sr-only")

    (img_html + sr_html + remaining).html_safe
  end

  def dropcap_img_for(char, height_px:)
    image_tag(File.join("decorated_letters", "letter_#{char.downcase}.png"),
              class: "dropcap",
              alt: char,
              "aria-hidden": true,
              height: height_px)
  end
end
