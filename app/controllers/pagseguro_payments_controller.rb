class PagseguroPaymentsController < Spree::BaseController
  skip_before_filter :verify_authenticity_token      
#  before_filter :load_object, :only => :notification
  layout 'application'
  
  resource_controller :singleton
  belongs_to :order

  create.response do |wants|
    wants.html do 
      render :nothing => true    
    end
  end

  def notification
    # First we process the request to create a notification object.
    notification = Spree::Pagseguro::Notification.new(request.raw_post)
    
    # Verifies if theres something in the notification.
    # Pagseguro's robot passes a notification, users passes nothing and expect a response page.
    is_robot = true
    
    if is_robot
      # Then we must discover to which order it refers to.
      refered_order = Order.find_by_number(notification.reference)
      
      if refered_order
        # Is this the first notification received?
        if !refered_order.pagseguro_payment
          logger.info("First notification received for #{refered_order.number}.")
          
          # Creates the payment object
          a_payment = PagseguroPayment.new(:email => notification.client_email)
          refered_order.pagseguro_payment = a_payment

          # Create a transaction which records the details of the notification
          a_transaction = PagseguroTxn.new(:transaction_id => notification.transaction_id, 
                             #:amount => notification.gross, 
                             #:fee => notification.fee,
                             #:currency_type => notification.currency, 
                             :status => notification.transaction_status, 
                             :received_at => notification.received_at)
          a_payment.txns << a_transaction
        else
          logger.info("Another notification received for #{refered_order.number}.")
          # Load the payment object.
          # Creates the payment object
          a_payment = refered_order.pagseguro_payment

          # Create a transaction which records the details of the notification
          a_transaction = PagseguroTxn.new(:transaction_id => notification.transaction_id, 
                             #:amount => notification.gross, 
                             #:fee => notification.fee,
                             #:currency_type => notification.currency, 
                             :status => notification.transaction_status, 
                             :received_at => notification.received_at)
          a_payment.txns << a_transaction
        end
        
        refered_order.update_attribute("ip_address", request.env['REMOTE_ADDR'] || "unknown")

        # We then send back the request to be validated adding two more fields Comando=validar&Token=00000000000000
        # So be can really trust it came from PagSeguro.
        verification_status = "VERIFICADO"
        if verification_status == "VERIFICADO"
          # Calculate here total extra taxes.
          extra_taxes = "0"
          # Calculate here total price.
          total_price = refered_order.total
          
          case notification.transaction_status
          when "Completo"
            if total_price == refered_order.total
              refered_order.pay!
              refered_order.update_attribute("tax_amount", extra_taxes.to_d) if extra_taxes
              refered_order.update_attribute("ship_amount", notification.shipping_price) if notification.shipping_price     
            else
              refered_order.fail_payment!
              logger.error("Incorrect order total during PagSeguro's notification, please investigate (PagSeguro processed #{total_price}, and order total is #{refered_order.total})")
            end
          else
            refered_order.fail_payment!
            logger.info("Received an unexpected status for order: #{refered_order.number}")
          end
        elsif verification_status == "FALSO"
          logger.info("PagSeguro did not recognised the notification.")
        else
          logger.info("Unexpected verification error, received #{verification_status}.")
        end
        
        
        
        
        
      else
        logger.error("No order was found with the received reference, we don't know what to do with this notification. Reference: #{ notification.reference }.")
      end
    else # is_robot
      # Its an user.

      # remove order from the session (its not really practical to allow the user to edit the session anymore)
      session[:order_id] = nil

      # Here we must show the response page.
      # How do we mark the order as completed if we do not know which order the user did in this point?
    end # is_robot


    if session[:order_id]
      session_order = Order.find(session[:order_id])
      session_order.update_attribute("checkout_complete", true) 
      # remove order from the session (its not really practical to allow the user to edit the session anymore)
      session[:order_id] = nil
      redirect_to order_url(session_order) and return
  end

#    if logged_in?
#      @order.update_attribute("user", current_user)
#      #redirect_to order_url(@order) and return
#    else
#      flash[:notice] = "Please create an account or login so we can associate this order with an account"
#      session[:return_to] = "#{order_url(@order)}?payer_id=#{@order.pagseguro_payment.payer_id}"
#      redirect_to signup_path
#    end

  end # notification

end
