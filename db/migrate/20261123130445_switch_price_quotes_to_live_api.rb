# Prices now come from the Binance API instead of a manual list:
# - remove the manual price list (price_entries) and the link to it
# - record which USD -> INR rate and which source each quote used
class SwitchPriceQuotesToLiveApi < ActiveRecord::Migration[8.1]
  def up
    # Existing quotes are simulated prices from the manual list. Clear them so
    # the first live price isn't compared against a made-up one.
    execute "DELETE FROM price_quotes"

    remove_reference :price_quotes, :price_entry, foreign_key: { on_delete: :nullify }, index: true
    drop_table :price_entries

    add_column :price_quotes, :usd_inr_rate, :decimal, precision: 10, scale: 4, null: false
    add_column :price_quotes, :source, :string, null: false
  end

  def down
    remove_column :price_quotes, :source
    remove_column :price_quotes, :usd_inr_rate

    create_table :price_entries do |t|
      t.string :metal, null: false
      t.decimal :price_inr, precision: 12, scale: 2, null: false
      t.decimal :price_usd, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :price_entries, :metal

    add_reference :price_quotes, :price_entry, null: true, foreign_key: { on_delete: :nullify }
  end
end
