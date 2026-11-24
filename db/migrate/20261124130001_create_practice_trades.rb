# One leveraged UP/DOWN practice trade on gold or silver.
# P&L = stake × leverage × % price move, and the loss can never exceed the stake.
class CreatePracticeTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :practice_trades do |t|
      # No separate index: the [practice_account_id, status] index below covers it.
      t.references :practice_account, null: false, index: false, foreign_key: { on_delete: :cascade }

      t.string :metal, null: false                 # "gold" or "silver"
      t.string :direction, null: false             # "up" or "down"
      t.decimal :stake_inr, precision: 14, scale: 2, null: false
      t.integer :leverage, null: false             # 5, 10, 20 or 50
      t.integer :duration_seconds, null: false     # 30, 60, 120 or 300

      # Binance prices in USD. 4 decimals so small moves aren't lost to rounding.
      t.decimal :entry_price_usd, precision: 14, scale: 4, null: false
      t.decimal :exit_price_usd, precision: 14, scale: 4

      t.string :status, null: false, default: "open" # "open" or "closed"
      t.string :close_reason                          # "expired", "manual" or "stopped_out"
      t.decimal :pnl_inr, precision: 14, scale: 2     # profit (+) or loss (-), set on close

      t.datetime :opened_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :closed_at

      t.timestamps
    end

    # "This account's open trades" and "trades that are past their expiry".
    add_index :practice_trades, [ :practice_account_id, :status ]
    add_index :practice_trades, [ :status, :expires_at ]
  end
end
