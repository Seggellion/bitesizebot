module Admin
    class ProductListingsController < ApplicationController
     before_action :set_product

  def create
    
    @product_listing = @product.product_listings.new(product_listing_params)
    if @product_listing.save
      redirect_to edit_admin_product_path(@product), notice: "Listing added."
    else
      redirect_to edit_admin_product_path(@product), alert: "Could not add listing: #{@product_listing.errors.full_messages.to_sentence}"
    end
  end

  def destroy
    @listing = @product.product_listings.find(params[:id])
    @listing.destroy
    redirect_to edit_admin_product_path(@product), notice: "Listing removed."
  end

  private

  def set_product
    @product = Product.find_by_slug(params[:product_id])
  end

  def product_listing_params
    params.require(:product_listing).permit(:npc_type, :city_id, :shard_id, :override_price)
  end

    end
  end
  