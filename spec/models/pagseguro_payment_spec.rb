require File.dirname(__FILE__) + '/../spec_helper'

module PagseguroPaymentSpecHelper
  def valid_pagseguro_payment_attributes
    {
      :state => "waiting_for_status_definition",
      :order => mock_model(Order)
    }
  end
end

describe PagseguroPayment do
  include PagseguroPaymentSpecHelper
  
  before(:each) do
    @pagseguro_payment = PagseguroPayment.new
  end

  it "should not be valid when empty" do
    @pagseguro_payment.should_not be_valid
  end

  ['order'].each do |field|
    it "should require #{field}" do
      @pagseguro_payment.should_not be_valid
      @pagseguro_payment.errors.full_messages.should include("#{field.intern.l(field).humanize} #{:error_message_blank.l}")
    end
  end

  it "should be valid when having correct information" do
    @pagseguro_payment.attributes = valid_pagseguro_payment_attributes
    @pagseguro_payment.should be_valid
  end
  
  describe "state transition" do

    before(:each) do
      @pagseguro_payment.attributes = valid_pagseguro_payment_attributes
      @pagseguro_payment.order.stub!(:cancel!).and_return(true)
      @pagseguro_payment.order.stub!(:approve!).and_return(true)
    end

    # Here we are waiting for a definition of the payment from the gateway, as we don't know what type of
    # payment was chosen or if it was abandoned.
    describe "from waiting_for_status_definition" do
      before(:each) do
        @pagseguro_payment.state = "waiting_for_status_definition"
      end

      # If the chosen payment method is creditcard it will be marked as payment_being_analyzed and will
      # took at most 2 usefull days to be analyzed with the creditcard operator and be canceled or approved.
      it "should transition to payment_being_analyzed when called analyze_payment" do
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "payment_being_analyzed"
      end

      # If the chosen payment method is bank payment slip it will be marked as waiting_for_payment and if paid
      # will took at most 3 usefull days to be identified in the gateway's system and be approved or if expired
      # be canceled.
      it "should transition to waiting_for_payment when called wait_for_payment" do
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "waiting_for_payment"
      end

      # If no response was received it will expire and be marked as status_definition_expired.
      it "should transition to status_definition_expired when called expire" do
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "status_definition_expired"
      end

      # We cannot cancel a payment that was never being done.
      it "should not transition to payment_canceled when called cancel_payment" do
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "waiting_for_status_definition"
      end
      
      # We cannot approve a payment that was never being done.
      it "should not transition to payment_approved when called approve_payment" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "waiting_for_status_definition"
      end

      # We cannot say the payment was credited in our gateway account if it was never being done.
      it "should not transition to payment_completed when called complete_payment" do
        @pagseguro_payment.complete_payment
        @pagseguro_payment.state.should == "waiting_for_status_definition"
      end
    end

    # Here we already know that the chosen type of payment was creditcard.
    describe "from payment_being_analyzed" do
      before(:each) do
        @pagseguro_payment.state = "payment_being_analyzed"
      end

      # Something wrong happened with the analisys of the creditcard and the payment was canceled.
      it "should transition to payment_canceled when called cancel_payment" do
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "payment_canceled"
      end

      # Everything is fine with the analisys of the creditcard and the payment was approved.
      it "should transition to payment_approved when called approve_payment" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "payment_approved"
      end

      # The type of payment chosen cannot change in the middle of the process.
      it "should not transition to waiting_for_payment when called wait_for_payment" do
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "payment_being_analyzed"
      end

      # The payment cannot expire it needs to be canceled or approved.
      it "should not transition to expired when called expire" do
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "payment_being_analyzed"
      end

      # We cannot say the payment was credited in our gateway account if it was not even approved yet.
      it "should not transition to payment_completed when called complete_payment" do
        @pagseguro_payment.complete_payment
        @pagseguro_payment.state.should == "payment_being_analyzed"
      end
    end
    
    # Here we already know that the chosen type of payment was bank payment slip.
    describe "from waiting_for_payment" do
      before(:each) do
        @pagseguro_payment.state = "waiting_for_payment"
      end

      # Three usefull days passed from the payment slip expiring date and the payment was not identified,
      # so the payment was canceled.
      it "should transition to payment_canceled when called cancel_payment" do
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "payment_canceled"
      end

      # Everything is fine with the payment slip and a payment was identified.
      it "should transition to payment_approved when called approve_payment" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "payment_approved"
      end

      # The type of payment chosen cannot change in the middle of the process.
      it "should not transition to payment_being_analyzed when called analyze_payment" do
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "waiting_for_payment"
      end

      # The payment cannot expire it needs to be canceled or approved.
      it "should not transition to expired when called expire" do
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "waiting_for_payment"
      end

      # We cannot say the payment was credited in our gateway account if it was not even approved yet.
      it "should not transition to payment_completed when called complete_payment" do
        @pagseguro_payment.complete_payment
        @pagseguro_payment.state.should == "waiting_for_payment"
      end
    end

    # Here we already know that the payment was approved.
    describe "from payment_approved" do
      before(:each) do
        @pagseguro_payment.state = "payment_approved"
      end

      # Fourteen running days passed from the date the payment was approved and we are being credited in our
      # gateway's account.
      it "should transition to payment_completed when called complete_payment" do
        @pagseguro_payment.complete_payment
        @pagseguro_payment.state.should == "payment_completed"
      end

      # All other states should not be available.
      it "should not transition to any state other than payment_completed" do
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "payment_approved"
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "payment_approved"
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "payment_approved"
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "payment_approved"
      end
    end

    # Here we already know that the payment was completed.
    describe "from payment_completed" do
      before(:each) do
        @pagseguro_payment.state = "payment_completed"
      end

      # payment_completed is a final state it cannot change to anything else.
      it "should not transition to any other state" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "payment_completed"
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "payment_completed"
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "payment_completed"
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "payment_completed"
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "payment_completed"
      end
    end

    # Here we already know that the payment was canceled.
    describe "from payment_canceled" do
      before(:each) do
        @pagseguro_payment.state = "payment_canceled"
      end

      # payment_canceled is a final state it cannot change to anything else.
      it "should not transition to any other state" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "payment_canceled"
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "payment_canceled"
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "payment_canceled"
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "payment_canceled"
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "payment_canceled"
      end
    end

    # Here we already know that the payment was expired.
    describe "from status_definition_expired" do
      before(:each) do
        @pagseguro_payment.state = "status_definition_expired"
      end

      # status_definition_expired is a final state it cannot change to anything else.
      it "should not transition to any other state" do
        @pagseguro_payment.approve_payment
        @pagseguro_payment.state.should == "status_definition_expired"
        @pagseguro_payment.analyze_payment
        @pagseguro_payment.state.should == "status_definition_expired"
        @pagseguro_payment.expire
        @pagseguro_payment.state.should == "status_definition_expired"
        @pagseguro_payment.wait_for_payment
        @pagseguro_payment.state.should == "status_definition_expired"
        @pagseguro_payment.cancel_payment
        @pagseguro_payment.state.should == "status_definition_expired"
      end
    end

  end

end