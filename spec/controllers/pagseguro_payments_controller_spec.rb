require File.dirname(__FILE__) + '/../spec_helper'

module PagseguroPaymentsControllerSpecHelper
  def valid_pagseguro_payment_post_data
    {
      :VendedorEmail    => "test@example.com",
      :TransacaoID      => "123XYZ",
      :Referencia       => "1",
      :TipoFrete        => "FR",
      :ValorFrete       => "10,99",
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
      :ProdValor_1      => "5,23",
      :ProdQuantidade_1 => "2",
      :ProdFrete_1      => "0,00",
      :ProdExtras_1     => "0,00",
      :NumItens         => "1"
    }
  end
end

describe PagseguroPaymentsController do
  include PagseguroPaymentsControllerSpecHelper

  before(:each) do
    @pagseguro_payment = mock_model(PagseguroPayment, :null_object => true)
  end
  
  # POST is supposed to be used by the gateway's robot to send notifications, here we describe it being
  # issued with different kinds of data, valid, invalid, blank, etc and in wrong states.
  # The transmit action is supposed to drop the order in an "waiting_for_payment_response" state and clean
  # the order in the session already.
  describe "handling POST /pagseguro_payment/notification" do
    before(:each) do
      @order = mock_model(Order, :null_object => true)
    end

    describe "with valid POST data" do
      before(:each) do
        # Mock the notification.
        @notification = mock_model(Notification, :null_object => true)
        Notification.stub!(:create).and_return(@notification)
        @notification.stub!(:empty?).and_return(false)
        @notification.stub!(:valid?).and_return(true)
        @notification.stub!(:acknowledge).and_return(true)
      end
      
      describe "and being the first transaction" do
        it "should create a new pagseguro_payment and pagseguro_txn" do
          @order.stub!(:pagseguro_payment).and_return(nil, @pagseguro_payment)
          @order.should_receive(:pagseguro_payment=)

          @notification.stub!(:StatusTransacao).and_return("Em Análise")
          @notification.stub!(:order).and_return(@order)

          post :notification, valid_pagseguro_payment_post_data
        end
      end
      
      describe "notifying payment_being_analyzed" do
        it "should mark the payment as payment_being_analyzed" do
          @pagseguro_payment.should_receive(:analyze_payment!)
          
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          @notification.stub!(:StatusTransacao).and_return("Em Análise")
          @notification.stub!(:order).and_return(@order)

          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Em Análise")
        end
      end
    
      describe "notifying waiting_for_payment" do
        it "should mark the payment as waiting_for_payment" do
          @pagseguro_payment.should_receive(:wait_for_payment!)
          
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          @notification.stub!(:StatusTransacao).and_return("Aguardando Pagto")
          @notification.stub!(:order).and_return(@order)

          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Aguardando Pagto")
        end
      end

      describe "notifying payment_approved" do
        before(:each) do
          @notification.stub!(:StatusTransacao).and_return("Aprovado")
          @notification.stub!(:order).and_return(@order)
        end
        
        it "should mark the payment as payment_approved" do
          @pagseguro_payment.should_receive(:approve_payment!)
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Aprovado")
        end

        it "should mark the payment's order as ready_to_ship when in payment_being_analyzed" do
          @pagseguro_payment = PagseguroPayment.create({:order => @order})
          @pagseguro_payment.state = "payment_being_analyzed"
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          @order.should_receive(:approve!)
          
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Aprovado")
        end
      end
    
      describe "notifying payment_canceled" do
        before(:each) do
          @notification.stub!(:StatusTransacao).and_return("Cancelado")
          @notification.stub!(:order).and_return(@order)
        end
        
        it "should mark the payment as payment_canceled" do
          @pagseguro_payment.should_receive(:cancel_payment!)
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Cancelado")
        end

        it "should mark the payment's order as canceled when in waiting_for_payment" do
          @pagseguro_payment = PagseguroPayment.create({:order => @order})
          @pagseguro_payment.state = "waiting_for_payment"
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          
          @order.should_receive(:cancel!)
          
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Cancelado")
        end

      end

      describe "notifying payment_completed" do
        it "should mark the payment as payment_completed" do
          @pagseguro_payment.should_receive(:complete_payment!)
          @order.stub!(:pagseguro_payment).and_return(@pagseguro_payment)
          @notification.stub!(:StatusTransacao).and_return("Completo")
          @notification.stub!(:order).and_return(@order)
          
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Completo")
        end
      end
      
      describe "when its order has not completed the checkout process yet" do
        it "should be ignored and log the error" do
          post :notification, valid_pagseguro_payment_post_data.with(:StatusTransacao => "Completo")
          response.should be_success

          response.body.should == " "
        end
      end

    end

    describe "without POST data" do
      it "should ignore the request and log the errors" do
        post :notification
        response.should be_success

        response.body.should == " "
      end
    end

    describe "with invalid POST data" do
      it "should ignore the request and log the errors"
    end

  end

  # GET is supposed to be used by the user after finished the payment to receive a final message, here
  # we describe it being requested in valid and invalid states in the checkout process.
  # The transmit action is supposed to drop the order in an "waiting_for_payment_response" state and clean
  # the order in the session already.
  describe "handling GET /pagseguro_payment/notification" do
    
    describe "when there is a transmited order in the session" do
      before(:each) do
        session[:transmited_order_id] = 1
        @order = mock_model(Order, :null_object => true)
        @controller.stub!(:find_order).and_return(@order)
        Order.stub!(:find).and_return(@order)
        @order.stub!(:state).and_return("waiting_for_payment_response")
      end
      
      it "should show response screen to user" do
        get :notification
        response.should be_redirect
        response.should redirect_to(:controller => 'orders', :action => 'finished', :id => @order.id)
      end

      it "should clean the transmited order in the session" do
        get :notification
        session[:transmited_order_id].should be_nil
      end
    end

    describe "when there is not a transmited order in the session" do
      it "should do nothing" do
        get :notification
        response.should be_success

        response.body.should == " "
      end
    end
  end

end
