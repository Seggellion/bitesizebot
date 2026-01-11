module Admin
    class ProductsController < ApplicationController
   before_action :set_product, only: %i[edit update publish unpublish
                                         update_category add_tag remove_tag]
      def index
       @products = Product.order(:title)
      end
  
      def new
        @product = Product.new
      end
  
def create
  raw_content = params[:product][:content]
  processed_content = convert_h1_to_h2(raw_content.to_s)

  @product = Product.new(product_params.except(:content))

  if @product.save
    @product.content = processed_content
    redirect_to admin_products_path, notice: 'Product was successfully created.'
  else
    render :new
  end
end

   def add_tag
      tag = Tag.find_or_create_by(name: params[:name].strip)
      @product.tags << tag unless @product.tags.exists?(tag.id)

      # Return the rendered tag “pill” so Stimulus can append it
      render partial: 'admin/products/tag', locals: { product: @product, tag: tag }
    end

    def remove_tag
      tag = @product.tags.find_by(id: params[:tag_id])
      @product.tags.destroy(tag) if tag
      head :ok
    end
  
      def edit
        
      end
  
 def publish
    if @product.update(published: true)
      redirect_to admin_product_path(@product), notice: "Product published successfully."
    else
      redirect_to admin_product_path(@product), alert: "Failed to publish product."
    end
  end

   def unpublish
    if @product.update(published: false)
      redirect_to admin_product_path(@product), notice: "Product unpublished successfully."
    else
      redirect_to admin_product_path(@product), alert: "Failed to unpublish product."
    end
  end

    def remove_image
      
      @product = Product.find_by_slug(params[:product_id])
      
      signed_id = params[:signed_id]

      if @product && signed_id
        blob = ActiveStorage::Blob.find_signed(signed_id)
        attachment = @product.images.find { |img| img.blob_id == blob.id }
        attachment&.purge
      end

      redirect_to edit_admin_product_path(@product), notice: "Image removed"
    end


    def update
    
      # Attach new images without overwriting existing ones
      if params[:product][:images].present?
        params[:product][:images].each do |image|
          @product.images.attach(image)
        end
      end

      # Update other attributes (excluding images to avoid overwriting)
      if @product.update(product_params.except(:images, :remove_images).to_h)
        if @product.content.present?
          @product.content.body = convert_h1_to_h2(@product.content.body.to_s)
          @product.content.save
        end
        redirect_to edit_admin_product_path(@product), notice: 'Product was successfully updated.'
      else
        render :edit, alert: 'Failed to update the product.'
      end
    end

          

      def update_category

        if @product.update(product_params)
          render json: { success: true }
        else
          render json: { success: false }
        end
      end

  
      def destroy
        @product = Product.find(params[:id])
        @product.destroy
        redirect_to admin_products_path, notice: 'Product was successfully deleted.'
      end
  
      private
  
def set_product
  
  @product = Product.find_by(id: params[:id]) || Product.find_by(slug: params[:id])

  unless @product
    redirect_to admin_products_path, alert: "Product not found"
  end
end


      def convert_h1_to_h2(html)
        # A simplistic approach using gsub:
        html.gsub(/<h1>/, "<h2>").gsub(/<\/h1>/, "</h2>")
      end

        def product_params
      permitted = params.require(:product).permit(
          :title, :content, :price, :compare_at_price,
          :shopify_product_id, :shopify_variant_id, :slug,
          :meta_description, :meta_keywords,
          :item_id, :icon_path, :requirements
        )

            # Cast textarea input to a Hash if it’s still a String
              if permitted[:requirements].is_a?(String)
                begin
                  permitted[:requirements] = JSON.parse(permitted[:requirements])
                rescue JSON::ParserError
                  permitted.delete(:requirements)         # ignore bad JSON rather than break the save
                end
              end

              permitted
  end

    end
  end
  