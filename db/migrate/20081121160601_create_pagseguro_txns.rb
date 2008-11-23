class CreatePagseguroTxns < ActiveRecord::Migration
  def self.up
    create_table :pagseguro_txns do |t|
      t.references :pagseguro_payment
      t.string :transaction_id
      t.decimal :amount, :precision => 8, :scale => 2
      t.decimal :fee, :precision => 8, :scale => 2
      t.string :currency_type
      t.string :status
      t.datetime :received_at
      t.timestamps
      

#      t.string :seller_email
#      t.string :reference
#      t.string :transaction_id
#      t.string :transaction_status
#      t.string :client_name
#      t.string :client_email
#      t.string :client_adress1
#      t.string :client_number
#      t.string :client_adress2
#      t.string :client_bairro
#      t.string :client_city
#      t.string :client_state
#      t.string :client_zip
#      t.string :client_phone
#      t.string :shipping_type
#      t.string :shipping_price
#      t.string :extra
#      t.string :notes
#      t.string :payment_type
#      t.string :number_of_items
#      t.datetime :received_at
#      t.timestamps
      
    end
  end

  def self.down
    drop_table :pagseguro_txns
  end
end
