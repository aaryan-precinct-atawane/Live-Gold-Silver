class CreatePriceQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :price_quotes do |t|
      t.string :metal, null: false
      t.decimal :price_inr, precision: 12, scale: 2, null: false
      t.decimal :price_usd, precision: 12, scale: 2, null: false
      t.datetime :recorded_at, null: false
      # Which manual entry this quote came from. Optional, because a future API
      # source won't have one, and it is cleared if the entry is deleted.
      t.references :price_entry, null: true, foreign_key: { on_delete: :nullify }

      t.timestamps
    end

    add_index :price_quotes, [ :metal, :recorded_at ]
  end
end
