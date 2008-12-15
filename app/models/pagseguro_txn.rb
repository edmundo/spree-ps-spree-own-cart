class PagseguroTxn < ActiveRecord::Base
  belongs_to :pagseguro_payment

  validates_presence_of :pagseguro_payment
end
