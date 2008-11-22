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
    end
  end

  def self.down
    drop_table :pagseguro_txns
  end
end
