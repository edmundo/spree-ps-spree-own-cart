class PagseguroPaymentsController < Spree::BaseController
  skip_before_filter :verify_authenticity_token      
  #before_filter :load_object, :only => :notification
  layout 'application'
  
  resource_controller :singleton
  #belongs_to :order

  create.response do |wants|
    wants.html do 
      render :nothing => true    
    end
  end

  def notification
    # First we process the request to create a notification object.
    a_notification = Notification.create
    a_notification.parse!(request.raw_post)
    
    # Verifies if theres something in the notification.
    if !a_notification.empty?
      # Anti-spoofing validation.
      if !a_notification.valid?
        logger.info "Uma notificação acaba de ser recusada. Segue a lista dos erros de validação: #{a_notification.errors.full_messages}."
        return false
      end
      
      # Create a transaction which records the details of the notification
      a_transaction = PagseguroTxn.new(
        :transaction_id => a_notification.TransacaoID, 
        :reference => a_notification.Referencia,
        :shipping_type => a_notification.TipoFrete,
        :shipping_price => a_notification.ValorFrete,
        :notes => a_notification.Anotacao,
        :received_at => Time.now.to_s(:db),
        :payment_type => a_notification.TipoPagamento,
        :transaction_status => a_notification.StatusTransacao,
        :number_of_items => a_notification.NumItens,
        :items_price => a_notification.items_price,
        :items_shipping_price => a_notification.items_shipping_price,
        :items_extras => a_notification.items_extras
      )

      # Is this the first notification received?
      if !a_notification.order.pagseguro_payment
        # Creates the payment object
        a_payment = PagseguroPayment.new(:email => a_notification.CliEmail)
        a_notification.order.pagseguro_payment = a_payment
      else
        # Load the payment object.
        a_payment = a_notification.order.pagseguro_payment
      end

      a_payment.txns << a_transaction
      
      # We then send back the request to be validated adding two more fields.
      # So be can really trust it came from PagSeguro.
      if a_notification.acknowledge(Spree::Pagseguro::Config[:token])
        case a_notification.StatusTransacao
        when "Completo"
          a_notification.order.pagseguro_payment.complete_payment!
        when "Aguardando Pagto"
          a_notification.order.pagseguro_payment.wait_for_payment!
        when "Aprovado"
          a_notification.order.pagseguro_payment.approve_payment!
        when "Em Análise"
          a_notification.order.pagseguro_payment.analyze_payment!
        when "Cancelado"
          a_notification.order.pagseguro_payment.cancel_payment!
        else
          a_notification.order.pagseguro_payment.cancel_payment!
          logger.info("Received an unexpected status (#{a_notification.StatusTransacao}) for order: #{a_notification.order}")
        end
      else
        logger.info("Unexpected verification response received.")
      end
      
      # In tests clean the session 
      if Spree::Pagseguro::Config[:always_use_sandbox] || RAILS_ENV == 'development'
        clean_session_information
      end
      
      # Don't render anything for a notification.
      render :nothing => true
    else # notification.raw empty
      # Its an user.
      
      # Theres an order in an state ready_to_transmit, this means it was already saved and passed by the
      # other states.
      if @order.state == "ready_to_transmit"
         @order.wait_for_payment_response!
         clean_session_information
         # Here we must show the response page.
      # The filter always create an order, this means that here a new order was created, or that the order
      # was not passed the previous states yet.
      else
        # Here we must to render nothing, and simply ignore this request.
        render :nothing => true
      end  
    end # is_robot

  end # notification
  
  private
  
  def clean_session_information
    # As we are not executing the checkout method on order controller we need to update
    # some properties here. 
    if session[:order_id]
      session_order = Order.find(session[:order_id])
      session_order.update_attribute("ip_address", request.env['REMOTE_ADDR'] || "unknown")
      session_order.update_attribute("checkout_complete", true) 
      # remove order from the session (its not really practical to allow the user to edit the session anymore)
      session[:order_id] = nil

      if logged_in?
        session_order.update_attribute("user", current_user)
        #redirect_to order_url(session_order)
      else
        flash[:notice] = "Please create an account or login so we can associate this order with an account"
        #session[:return_to] = "#{order_url(session_order)}"
        redirect_to signup_path
      end
    end
  end

end
