# A practice (dummy money) trading account. There is no login: each browser
# gets one account, remembered by a random token stored in a signed cookie.
class CreatePracticeAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :practice_accounts do |t|
      t.string :token, null: false
      # Virtual rupees. Every new account starts with ₹10,00,000.
      t.decimal :balance_inr, precision: 14, scale: 2, null: false, default: 1_000_000

      t.timestamps
    end

    add_index :practice_accounts, :token, unique: true
  end
end
