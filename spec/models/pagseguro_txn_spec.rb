require File.dirname(__FILE__) + '/../spec_helper.rb'

module PagseguroTxnSpecHelper
  def valid_pagseguro_txn_attributes
    {
      :transaction_id => "XYZ",
      :reference => 1,
      :transaction_status => "Completo",
      :number_of_items => 2,
      :items_price => 10,
      :items_shipping_price => 0,
      :items_extras => 0
    }
  end
end

describe PagseguroTxn do
  include PagseguroTxnSpecHelper

  before(:each) do
    @pagseguro_txn = PagseguroTxn.new
  end
  
  it "should not be valid when empty" do
    @pagseguro_txn.should_not be_valid
  end

  ['pagseguro_payment'].each do |field|
    it "should require #{field}" do
      @pagseguro_txn.should_not be_valid
      @pagseguro_txn.errors.full_messages.should include("#{field.intern.l(field).humanize} #{:error_message_blank.l}")
    end
  end

  it "should be valid when having correct information" do
    @pagseguro_txn.attributes = valid_pagseguro_txn_attributes.with(:pagseguro_payment => mock_model(PagseguroPayment))
    @pagseguro_txn.should be_valid
  end

end
