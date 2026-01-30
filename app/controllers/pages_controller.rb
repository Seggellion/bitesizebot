class PagesController < ApplicationController
    before_action :set_page, only: [:show]
    before_action :prepend_theme_view_path
  before_action :include_theme_helpers

def show
  template_file = @page.template_file.presence || 'default'
  theme_template_path = "pages/page-#{template_file}"
  fallback_template = "pages/page-default"

  # Custom logic for downloads
  if @page.slug == 'downloads'
    @downloads_by_shard = Download
      .includes(:shard)
      .group_by(&:shard)
      .sort_by { |shard, _| shard.name.downcase }
      .to_h
  end

  # ADD 'return' after authenticate_user! to prevent double rendering
  if @page.slug == 'bingo-card'
    authenticate_user! and return
    load_bingo_data
  end

  if @page.slug == 'giveaways'
    
    authenticate_user! and return    
    load_giveaways_data
  end

  if lookup_context.exists?(theme_template_path, [], false)
    render theme_template_path
  else
    render fallback_template
  end
end

def upload_screenshot
  authenticate_user!

  @medium = Medium.new(medium_params)
  @medium.user = current_user
  @medium.category = 'screenshot'
  @medium.approved = false

  if params[:file].present?
    uploaded_file = params[:file]
    @medium.file.attach(
      io: uploaded_file.tempfile,
      filename: uploaded_file.original_filename,
      content_type: uploaded_file.content_type
    )
  end

  if @medium.save
    redirect_to catch_all_page_path('screenshots'), notice: 'Your screenshot has been submitted and is awaiting approval.'
  else
    load_screenshot_data
    flash[:alert] = 'Failed to upload screenshot.'
    render "pages/page-#{@page.template_file.presence || 'default'}"
  end
end

def user_screenshots
         
  user = User.find_by(username: params[:username])

  if user
    screenshots = user.media.screenshots.where(approved: true).order(created_at: :desc)
    render json: {
      primary_image: screenshots.first&.file&.url,
      meta_description: screenshots.first&.meta_description,
      meta_keywords: screenshots.first&.meta_keywords,
      shard_name: screenshots.first&.shard.name,
      thumbnails: screenshots.map do |s|
        { url: s.file.url, meta_description: s.meta_description, shard_name: s.shard&.name }
      end
    }
  else
    render json: { error: 'User not found' }, status: :not_found
  end
end


    

    def index
      @pages = Page.all
    end
 
    private
    def prepend_theme_view_path
      theme_path = Rails.root.join("app", "themes", current_theme, "views")
      prepend_view_path theme_path
    end

    
    def medium_params
      params.permit(:file, :meta_description, :meta_keywords, :shard_id)
    end




  def load_giveaways_data
    @giveaways = Giveaway.open.order(created_at: :desc)
    @past_giveaways = Giveaway.completed.limit(5).order(drawn_at: :desc)
  end


  def load_bingo_data
  @game = BingoGame.current_or_latest
  return unless @game

  @bingo_card = current_user.bingo_cards.find_by(bingo_game: @game)

  if @bingo_card
    # We sort by row_number here so the vertical order is consistent everywhere
    @grouped_cells = @bingo_card.bingo_cells
                                .includes(:bingo_item)
                                .sort_by { |cell| cell.bingo_item.row_number || 0 }
                                .group_by { |cell| cell.bingo_item.column_letter }
    
    @columns = ["B", "I", "N", "G", "O"].first(@game.size)
  end
end
    
    def set_page
      @page = Page.friendly.find(params[:slug])
      
    end
    def include_theme_helpers
      
      theme_module = "#{current_theme}::PagesHelper"
      helper_module = theme_module.safe_constantize

      helper(helper_module) if helper_module
    end
  end
  