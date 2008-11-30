class CreatePagseguroTxns < ActiveRecord::Migration
  def self.up
    create_table :pagseguro_txns do |t|
      t.references :pagseguro_payment
      
      t.string :transaction_id
      t.string :reference
      t.string :shipping_type
      t.decimal :shipping_price, :precision => 8, :scale => 2
      t.string :notes
      t.datetime :received_at
      t.string :payment_type
      t.string :transaction_status

#      t.string :client_name
#      t.string :client_email
#      t.string :client_adress1
#      t.string :client_number
#      t.string :client_adress2
#      t.string :client_borough
#      t.string :client_city
#      t.string :client_state
#      t.string :client_zip
#      t.string :client_phone

      t.integer :number_of_items

#      t.integer :prod_id_x
#      t.string :prod_description_x
#      t.integer :prod_quantity_x
#      t.decimal :prod_price_x, :precision => 8, :scale => 2
#      t.decimal :prod_shipping_price_x, :precision => 8, :scale => 2
#      t.decimal :prod_extras_x, :precision => 8, :scale => 2

      t.decimal :items_price, :precision => 8, :scale => 2
      t.decimal :items_shipping_price, :precision => 8, :scale => 2
      t.decimal :items_extras, :precision => 8, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :pagseguro_txns
  end
end
