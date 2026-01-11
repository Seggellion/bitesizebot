module Admin
    class TransactionsController < Admin::ApplicationController
      before_action :set_transaction, only: [:edit, :update, :destroy]
  
      def index
        @transactions = Transaction.all.order(created_at: :desc)
      end
  
      def new
        @transaction = Transaction.new
      end
  
      def create
        @transaction = Transaction.new(transaction_params)
        @transaction.update(user_id: current_user.id)
        if @transaction.save
          redirect_to admin_transactions_path, notice: 'Transaction was successfully created.'
        else
          render :new
        end
      end
  
      def edit; end
  
      def update
        if @transaction.update(transaction_params)
          redirect_to admin_transactions_path, notice: 'Transaction was successfully updated.'
        else
          render :edit
        end
      end
  
      def destroy
        @transaction.destroy
        redirect_to admin_transactions_path, notice: 'Transaction was successfully deleted.'
      end
  
      private
  
      def set_transaction
        @transaction = Transaction.find_by_slug(params[:id])
      end
  
      def transaction_params
        params.require(:transaction).permit(:title, :description, :location, :start_time, :end_time)
      end
    end
  end
  