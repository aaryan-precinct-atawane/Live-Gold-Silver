class CreatePriceEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :price_entries do |t|
      t.string :metal, null: false
      t.decimal :price_inr, precision: 12, scale: 2, null: false
      t.decimal :price_usd, precision: 12, scale: 2, null: false

      t.timestamps
    end

    add_index :price_entries, :metal
  end
end
