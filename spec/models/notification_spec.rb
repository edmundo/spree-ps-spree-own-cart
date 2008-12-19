require File.dirname(__FILE__) + '/../spec_helper'

module NotificationSpecHelper
  
  def valid_notification_attributes
    Spree::Pagseguro::Config.set({:account => "test@example.com"})

    order = mock_model(Order, :null_object => true)
    order.stub!(:total).and_return(5.23 * 2)
    {
      :VendedorEmail    => "test@example.com",
      :TransacaoID      => "123XYZ",
      :Referencia       => "1",
      :TipoFrete        => "FR",
      :ValorFrete       => 10.99,
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
      :ProdFrete_1      => 2.30,
      :ProdExtras_1     => 1.20,
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

end
