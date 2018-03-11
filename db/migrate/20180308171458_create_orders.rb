class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :name
      t.references :cart

      t.string :status, default: :new
      t.string :shipping_method

      t.decimal :total_price
      t.decimal :taxed_total
      t.timestamps
    end
  end
end
