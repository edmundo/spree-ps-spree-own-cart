require File.dirname(__FILE__) + '/../spec_helper'

module NotificationSpecHelper
  
  def valid_notification_attributes
    Spree::Pagseguro::Config.set({:account => "test@example.com"})

    order = mock_model(Order, :null_object => true)
    order.stub!(:total).and_return((5.23 * 2) + 10.99) 
    {
      :VendedorEmail    => "test@example.com",
      :TransacaoID      => "123XYZ",
      :Referencia       => "1",
      :TipoFrete        => "FR",
      :Anotacao         => "Here goes some notes.",
      :DataTransacao    => "01/01/2008 12:30:10",
      :TipoPagamento    => "Cartão de Crédito",
      :StatusTransacao  => "Aprovado",
      :CliNome          => "John Doe",
      :CliEmail         => "john.doe@nowhere.com",
      :CliEndereco      => "Nowhere",
      :CliNumero        => "100",
      :CliComplemento   => "",
      :CliBairro        => "Nowhere",
      :CliCidade        => "Nowhere",
      :CliEstado        => "NW",
      :CliCEP           => "12345123",
      :CliTelefone      => "12345678",
      :ProdID_1         => "1",
      :ProdDescricao_1  => "Nothing",
      :ProdValor_1      => 5.23,
      :ProdQuantidade_1 => 2,
      :ProdExtras_1     => 0,
      :ProdFrete_1      => 10.99,
      :NumItens         => 1,
      :order            => order
    }
  end
end


describe Notification do
  include NotificationSpecHelper

  before(:each) do
    @notification = Notification.new
  end

  it "should be valid when having correct information" do
    @notification.attributes = valid_notification_attributes
    @notification.should be_valid
  end

  it "should not be valid when having a not valid TipoFrete" do
    @notification.attributes = valid_notification_attributes.with(:TipoFrete => "YZ")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'TipoFrete'.humanize} #{@notification.TipoFrete} não está incluído na lista")
  end

  it "should not be valid when having a not valid TipoPagamento" do
    @notification.attributes = valid_notification_attributes.with(:TipoPagamento => "Fiado")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'TipoPagamento'.humanize} #{@notification.TipoPagamento} não está incluído na lista")
  end

  it "should not be valid when having a not valid StatusTransacao" do
    @notification.attributes = valid_notification_attributes.with(:StatusTransacao => "Nenhum")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'StatusTransacao'.humanize} #{@notification.StatusTransacao} não está incluído na lista")
  end

  it "should have exactly 8 numberic characters on CliCEP" do
    @notification.attributes = valid_notification_attributes.with(:CliCEP => "12345-123")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'CliCEP'.humanize} #{@notification.CliCEP} deve conter exatamente oito dígitos numéricos sem o traço")
  end

  it "should only accept numeric NumItens" do
    @notification.attributes = valid_notification_attributes.with(:NumItens => "foo")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'NumItens'.humanize} #{:is_not_an_integer.l}")
  end

  it "should only accept integer NumItens" do
    @notification.attributes = valid_notification_attributes.with(:NumItens => 0.5)
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'NumItens'.humanize} #{:is_not_an_integer.l}")
  end

  it "should only accept positive NumItens" do
    @notification.attributes = valid_notification_attributes.with(:NumItens => -2)
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'NumItens'.humanize} #{:is_not_a_positive_number.l}")
  end

  it "should have a unique TransacaoID" do
    PagseguroTxn.stub!(:find_by_transaction_id).and_return(mock_model(PagseguroTxn, :null_object => true))
    @notification.attributes = valid_notification_attributes
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'TransacaoID'.humanize} #{:error_message_taken.l}")
  end

  it "should have a valid VendedorEmail" do
    @notification.attributes = valid_notification_attributes.with(:VendedorEmail => "another_acoount@@example.com")
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'VendedorEmail'.humanize} não é nosso endereço de e-mail.")
  end

  it "should reference an existing and valid order" do
    @notification.attributes = valid_notification_attributes.with(:order => nil)
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'order'.intern.l('order').humanize} não foi possível estabelecer um vínculo com pedido algum.")
  end

  it "should match its totals with its refered order totals" do
    @notification.attributes = valid_notification_attributes
    @notification.order.stub!(:total).and_return(99)
    @notification.should_not be_valid
    @notification.errors.full_messages.should include("#{'order'.intern.l('order').humanize} total não confere com a notificação, pedido: #{@notification.order.total}, notificação: #{@notification.items_total}.")
  end

end
