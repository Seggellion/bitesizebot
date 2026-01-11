module Admin
    class PagesController < ApplicationController
      before_action :set_page, only: [:update_category]
      def index
       @pages = Page.order(:title)
      end
  
      def new
        @page = Page.new
      end
  
      def create
        @page = Page.new(page_params)



        @page.content.body = convert_h1_to_h2(@page.content.body.to_s)

        if @page.save
          redirect_to admin_pages_path, notice: 'Page was successfully created.'
        else
          render :new
        end
      end
  
      def edit
        @page = Page.find_by_slug(params[:id])
      end
  
    def remove_image
      
      @page = Page.find_by_slug(params[:page_id])
      
      signed_id = params[:signed_id]

      if @page && signed_id
        blob = ActiveStorage::Blob.find_signed(signed_id)
        attachment = @page.images.find { |img| img.blob_id == blob.id }
        attachment&.purge
      end

      redirect_to edit_admin_page_path(@page), notice: "Image removed"
    end


    def update
      
      @page = Page.find_by_slug(params[:id])


      # Attach new images without overwriting existing ones
      if params[:page][:images].present?
        params[:page][:images].each do |image|
          @page.images.attach(image)
        end
      end

      # Update other attributes (excluding images to avoid overwriting)
      if @page.update(page_params.except(:images, :remove_images))
        if @page.content.present?
          @page.content.body = convert_h1_to_h2(@page.content.body.to_s)
          @page.content.save
        end
        redirect_to edit_admin_page_path(@page), notice: 'Page was successfully updated.'
      else
        render :edit, alert: 'Failed to update the page.'
      end
    end

          

      def update_category

        if @page.update(page_params)
          render json: { success: true }
        else
          render json: { success: false }
        end
      end

  
      def destroy
        @page = Page.find(params[:id])
        @page.destroy
        redirect_to admin_pages_path, notice: 'Page was successfully deleted.'
      end
  
      private
  
      def set_page
        
        @page = Page.find(params[:id])
      end

      def convert_h1_to_h2(html)
        # A simplistic approach using gsub:
        html.gsub(/<h1>/, "<h2>").gsub(/<\/h1>/, "</h2>")
      end

      def page_params
        params.require(:page).permit(:title, :content, :category_id, :meta_description, :meta_keywords, :template, images: [], remove_images: []).merge(user_id: current_user.id)

      end
    end
  end
  