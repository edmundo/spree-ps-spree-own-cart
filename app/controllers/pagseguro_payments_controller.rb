class PagseguroPaymentsController < Spree::BaseController
  skip_before_filter :verify_authenticity_token      
  #before_filter :load_object, :only => :notification
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
    if notification.raw

      # Sanity checks.

      # Verify if the seller email is ours, (someone can try to pay to another account and say he payed us).
      if notification.seller_email != Spree::Pagseguro::Config[:account]
        logger.error("Received a notification where the seller email is #{notification.seller_email}, but this address is not ours.")
        return false
      end
      # Verify if the transaction_id is unique, (someone can try a replay attack).
      a_transaction = PagseguroTxn.find_by_transaction_id(notification.transaction_id)
      if a_transaction
        logger.error("Received an already existent transaction id #{notification.transaction_id}, but it must be unique.")
        return false
      end
      # Verify if the refered order number exists (or we will not know to which order the notification is
      # refering to).
      refered_order = Order.find_by_number(notification.reference)
      if !refered_order
        logger.error("No order was found with the received refered number #{notification.reference}, we don't know what to do with this notification.")
        return false
      end

      # Calculate here total extra taxes.
      extra_taxes = "0"
      # Calculate here total price.
      total_price = refered_order.total
      # Verify if the totals match.
      if notification.transaction_status == "Completo"
        if total_price != refered_order.total
          refered_order.fail_payment!
          logger.error("Incorrect order total during PagSeguro's notification, please investigate (PagSeguro processed #{total_price}, and order total is #{refered_order.total})")
          return false
        end
      end

        
      # Is this the first notification received?
      if !refered_order.pagseguro_payment
        # Creates the payment object
        a_payment = PagseguroPayment.new(:email => notification.client_email)
        refered_order.pagseguro_payment = a_payment
    
        # Create a transaction which records the details of the notification
        a_transaction = PagseguroTxn.new(
          :transaction_id => notification.transaction_id, 
          :status => notification.transaction_status, 
          :received_at => notification.received_at
        )
        a_payment.txns << a_transaction
      else
        # Load the payment object.
        a_payment = refered_order.pagseguro_payment
    
        # Create a transaction which records the details of the notification
        a_transaction = PagseguroTxn.new(
          :transaction_id => notification.transaction_id, 
          :status => notification.transaction_status, 
          :received_at => notification.received_at
        )
        a_payment.txns << a_transaction
      end
      
    
      # We then send back the request to be validated adding two more fields.
      # So be can really trust it came from PagSeguro.
      if notification.acknowledge(Spree::Pagseguro::Config[:token])
        case notification.transaction_status
        when "Completo"
          refered_order.pay!
        else
          refered_order.fail_payment!
          logger.info("Received an unexpected status for order: #{refered_order.number}")
        end
      else
        logger.info("Unexpected verification error, received #{verification_status}.")
      end
          
          
          
          
          
    else # notification.raw empty
      # Its an user.

      # As we are not executing the checkout method on order controller we need to update
      # some properties here. 
      if session[:order_id]
        session_order = Order.find(session[:order_id])
        session_order.update_attribute("ip_address", request.env['REMOTE_ADDR'] || "unknown")
        session_order.update_attribute("checkout_complete", true) 
        # remove order from the session (its not really practical to allow the user to edit the session anymore)
        session[:order_id] = nil
        #redirect_to order_path(session_order) and return

        if logged_in?
          session_order.update_attribute("user", current_user)
          #redirect_to order_url(@order) and return
        else
          flash[:notice] = "Please create an account or login so we can associate this order with an account"
          #session[:return_to] = "#{order_url(@order)}?payer_id=#{@order.pagseguro_payment.payer_id}"
          redirect_to signup_path
        end
      end

      # Here we must show the response page.
    end # is_robot

  end # notification

end
