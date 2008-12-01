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
    if !notification.raw.empty?
      # Anti-spoofing validation.

      # Verify if the seller email in the notification is our.
      if notification.seller_email != Spree::Pagseguro::Config[:account]
        logger.error("Received a notification where the seller email is #{notification.seller_email}, but this address is not ours.")
        return false
      end
      # Verify if the transaction_id in the notification is unique.
      a_transaction = PagseguroTxn.find_by_transaction_id(notification.transaction_id)
      if a_transaction
        logger.error("Received an already existent transaction id #{notification.transaction_id}, but it must be unique.")
        return false
      end
      # Verify if the notification refered order number exists.
      refered_order = Order.find_by_number(notification.reference)
      if !refered_order
        logger.error("No order was found with the received refered number #{notification.reference}, we don't know what to do with this notification.")
        return false
      end
      # Calculate the notification prices.
      items_price = 0
      items_shipping_price = 0
      items_extras = 0
      (1..notification.number_of_items.to_i).to_a.each do |i|
        items_price += (notification.send("prod_price_#{i}").to_f * notification.send("prod_quantity_#{i}").to_i)
        items_shipping_price += (notification.send("prod_shipping_price_#{i}").to_f)
        items_extras += (notification.send("prod_extras_#{i}").to_f)
      end
      # Verify if the total order value in the notification is the same as in the order.
      if items_price != refered_order.total
        refered_order.fail_payment!
        logger.error("Incorrect order total during PagSeguro's notification, please investigate (PagSeguro processed #{items_price}, and order total is #{refered_order.total})")
        return false
      end

        
      # Create a transaction which records the details of the notification
      a_transaction = PagseguroTxn.new(
        :transaction_id => notification.transaction_id, 
        :reference => notification.reference,
        :shipping_type => notification.shipping_type,
        :shipping_price => notification.shipping_price,
        :notes => notification.notes,
        :received_at =>  Time.now.to_s(:db),
        :payment_type => notification.payment_type,
        :transaction_status => notification.transaction_status,
        :number_of_items => notification.number_of_items,
        :items_price => items_price,
        :items_shipping_price => items_shipping_price,
        :items_extras => items_extras
      )

      # Is this the first notification received?
      if !refered_order.pagseguro_payment
        # Creates the payment object
        a_payment = PagseguroPayment.new(:email => notification.client_email)
        refered_order.pagseguro_payment = a_payment
      else
        # Load the payment object.
        a_payment = refered_order.pagseguro_payment
      end

      a_payment.txns << a_transaction
      
    
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
      clean_session_information

      # Here we must show the response page.
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
