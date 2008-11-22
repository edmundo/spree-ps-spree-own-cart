class PagseguroPayment < ActiveRecord::Base
  has_many :pagseguro_txns
  belongs_to :order
  
  alias :txns :pagseguro_txns
end
