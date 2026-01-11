module Admin
    class DownloadsController < ApplicationController
      before_action :set_download, only: [:update_category]
      before_action :set_shards, only: [:edit, :update, :new]

      def index
        @downloads = Download.all
      end
  
      def new
        @download = Download.new
      end
  
      def create
        @download = Download.new(download_params)
        if @download.save
          redirect_to admin_downloads_path, notice: 'Download was successfully created.'
        else
          render :new
        end
      end
  
      def edit
        @download = Download.find_by_id(params[:id])
      end
  
      def update
        @download = Download.find_by_id(params[:id])
        if @download.update(download_params)
           redirect_to edit_admin_download_path(@download), notice: 'Download was successfully updated.'
        end
      end

      def update_category

        if @download.update(download_params)
          render json: { success: true }
        else
          render json: { success: false }
        end
      end

  
      def destroy
        @download = Download.find(params[:id])
        @download.destroy
        redirect_to admin_downloads_path, notice: 'Download was successfully deleted.'
      end
  
      private
  
      def set_download
        
        @download = Download.find(params[:id])
      end
      
            def set_shards
        
        @shards = Shard.all
      end
      def download_params
    params.require(:download).permit(:title, :description, :link_url, :link_text, :shard_id)

      end
    end
  end
  