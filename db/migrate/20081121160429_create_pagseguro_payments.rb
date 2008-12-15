class CreatePagseguroPayments < ActiveRecord::Migration
  def self.up
    create_table :pagseguro_payments do |t|
      t.references :order
      t.string :email
      t.string :payer_id
      t.string :state
      t.timestamps
    end
  end

  def self.down
    drop_table :pagseguro_payments
  end
end
