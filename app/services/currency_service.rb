# app/services/currency_service.rb
class CurrencyService
  class InsufficientFundsError < StandardError; end

  def self.update_balance(user:, amount:, type:, metadata: {})
    ActiveRecord::Base.transaction do
      # 1. Create the entry (this triggers the 'sufficient funds' validation)
      entry = user.ledger_entries.build(
        amount: amount,
        entry_type: type,
        metadata: metadata
      )

      if entry.save
        # 2. Update the user balance using increment! 
        # This performs an atomic SQL update: SET wallet = wallet + amount
        user.increment!(:wallet, amount)
        entry
      else
        raise InsufficientFundsError, entry.errors.full_messages.join(", ")
      end
    end
  end

  # Helper for transfers between two users
  def self.transfer(from_user:, to_user:, amount:, metadata: {})
    ActiveRecord::Base.transaction do
      update_balance(user: from_user, amount: -amount, type: 'transfer', metadata: metadata.merge(to_user_id: to_user.id))
      update_balance(user: to_user, amount: amount, type: 'transfer', metadata: metadata.merge(from_user_id: from_user.id))
    end
  end
end