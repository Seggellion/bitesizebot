# app/controllers/store_controller.rb
class StoreController < ApplicationController
    
 before_action :initialize_shopify_service

  def index
    @products = Product.where(published: true).order(created_at: :desc)
  end

  def show
    @product = Product.find_by!(slug: params[:slug], published: true)

      product_handle = params[:slug]
      shopify_product_raw = @shopify_service.fetch_product_by_handle(product_handle)
shopify_product_json = shopify_product_raw.transform_keys { |k| k.underscore }
 @shopify_product = OpenStruct.new(shopify_product_json) 
 price = @shopify_product.variants["edges"].first["node"]["price"]["amount"]
currency = @shopify_product.variants["edges"].first["node"]["price"]["currencyCode"]

@price_output = "Price: $#{price} #{currency}"

 images = shopify_product_json["images"]["edges"].map { |edge| edge["node"] }

  # 2. add variant images (some variants have nil image)
  variant_imgs = shopify_product_json["variants"]["edges"].filter_map { |e| e["node"]["image"] }
  images.concat(variant_imgs)

  # 3. deduplicate by src  (Shopify often re-uses the same asset on variants)
  uniq_images = images.uniq { |n| n["src"] }

  # 4. normalise to a shape the view/JS expect
  @product_images = uniq_images.map do |n|
    { src: n["src"],
      alt: n["altText"].presence || @product["title"],
      id:  n["id"] }       # id is useful for key helpers & analytics, not required
  end


  end


  
    def add_to_cart
      variant_id = params[:variant_id]
      
      cart_id = session[:cart_id] || @shopify_service.create_cart(current_user.minecraft_uuid)
      session[:cart_id] = cart_id

      
      @shopify_service.add_to_cart(cart_id, variant_id)

      redirect_to cart_path
    end
  
    def cart
        
  if session[:cart_id].present?
    @cart = @shopify_service.fetch_cart(session[:cart_id])
  else
    @cart = nil
  end

        render '/store/cart'
    end
  
    def remove_from_cart
        variant_id = params[:line_id]
        cart_id = session[:cart_id]

        @shopify_service.remove_from_cart(cart_id, variant_id)
        redirect_to cart_path, notice: 'Item removed from cart.'
    end

    def checkout
      @cart = @shopify_service.fetch_cart(session[:cart_id])
      
      redirect_to @cart["checkoutUrl"], allow_other_host: true
    end
  
    private
  
    def initialize_shopify_service
      @shopify_service = ShopifyService.new
    end

end
