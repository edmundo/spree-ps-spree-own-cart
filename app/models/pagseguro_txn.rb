class PagseguroTxn < ActiveRecord::Base
  belongs_to :pagseguro_payment
  validates_numericality_of :amount
end
