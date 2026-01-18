module Admin
  class CustomCommandsController < ApplicationController
    before_action :set_command, only: [:edit, :update, :destroy]

    def index
      @custom_commands = CustomCommand.all.order(:name)
    end

    def new
      @custom_command = CustomCommand.new
    end

    def create
      @custom_command = CustomCommand.new(command_params)      
      @custom_command.author = current_user.username
      if @custom_command.save
        redirect_to admin_custom_commands_path, notice: 'Command created.'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @custom_command.update(command_params)
        redirect_to admin_custom_commands_path, notice: 'Command updated.'
      else
        render :edit
      end
    end

    def destroy
      @custom_command.destroy
      redirect_to admin_custom_commands_path, notice: 'Command deleted.'
    end

    private

    def set_command
      @custom_command = CustomCommand.find(params[:id])
    end

    def command_params
      params.require(:custom_command).permit(:name, :response, :permission_level)
    end
  end
end