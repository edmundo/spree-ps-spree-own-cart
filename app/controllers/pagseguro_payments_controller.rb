class PagseguroPaymentsController < Spree::BaseController
  skip_before_filter :verify_authenticity_token      
  before_filter :load_object, :only => :notification
  layout 'application'
  
  resource_controller :singleton
  belongs_to :order

  create.response do |wants|
    wants.html do 
      render :nothing => true    
    end
  end

  # NOTE: The Pagseguro Data Automatic Return results in the creation of a PagseguroPayment
  def notification
    # Create a PagseguroPayment object.
    build_object
    load_object

    # First we process the request to create a notification object.
    notification = Spree::Pagseguro::Notification.new(request.raw_post)

    # We then send back the request to be validated adding two more fields Comando=validar&Token=00000000000000

    #if verification.status == "VERIFICADO"
    # Verifique se a notificação é pra você, o email recebido (VendedorEmail) deve ser o seu email
    # Verifique se o valor do pagamento está correto de acordo com a identificação do pedido

    # Verifique se a TransacaoID não foi previamente processada
    # Processe o pagamento salvando os dados em seu banco de dados
    #elsif notification.status == "FALSO"
    # LOG para investigação manual
    #else
    # Erro
    #end

    # mark the checkout process as complete (even if the return results in a failure - no point in letting the user 
    # edit the order now)
    @order.update_attribute("checkout_complete", true)                   
    object.update_attributes(:email => params[:CliEmail], :payer_id => "123456")
    

    # create a transaction which records the details of the notification
    object.txns.create(:transaction_id => notification.transaction_id, 
                       #:amount => notification.gross, 
                       #:fee => notification.fee,
                       #:currency_type => notification.currency, 
                       :status => notification.status, 
                       :received_at => notification.received_at)

    case notification.status
      when "Completed"
        @order.pay!
      when "Pending"
        @order.fail_payment!
        logger.info("Received an unexpected pending status for order: #{@order.number}")
      else
        @order.fail_payment!
        logger.info("Received an unexpected status for order: #{@order.number}")
      end
    end

#    if notification.acknowledge
#      case notification.status
#      when "Completed"
#        if ipn.gross.to_d == @order.total
#          @order.pay!
#          @order.update_attribute("tax_amount", params[:tax].to_d) if params[:tax]
#          @order.update_attribute("ship_amount", params[:mc_shipping].to_d) if params[:mc_shipping]          
#        else
#          @order.fail_payment!
#          logger.error("Incorrect order total during Paypal's notification, please investigate (Paypal processed #{ipn.gross}, and order total is #{@order.total})")
#        end
#      when "Pending"
#        @order.fail_payment!
#        logger.info("Received an unexpected pending status for order: #{@order.number}")
#      else
#        @order.fail_payment!
#        logger.info("Received an unexpected status for order: #{@order.number}")
#      end
#    else
#      @order.fail_payment!
#      logger.info("Failed to acknowledge Paypal's notification, please investigate [order: #{@order.number}]")
#    end

    
    @order.update_attribute("ip_address", request.env['REMOTE_ADDR'] || "unknown")
    # its possible that the IPN has already been received at this point so that
    unless @order.pagseguro_payment
      # create a payment and record the successful transaction
      pagseguro_payment = PagseguroPayment.create(:order => @order, :email => params[:payer_email], :payer_id => "123456")
      @order.pagseguro_payment = pagseguro_payment
      pagseguro_payment.txns.create(
#        :amount => params[:mc_gross].to_d, 
        :status => "Processed",
        :transaction_id => params[:TransacaoID],
#        :fee => params[:payment_fee],
#        :currency_type => params[:mc_currency],
        :received_at => params[:DataTransacao]
      )
      # advance the state
      @order.pend_payment!
    end
    
    # remove order from the session (its not really practical to allow the user to edit the session anymore)
    session[:order_id] = nil
    
    if logged_in?
      @order.update_attribute("user", current_user)
      redirect_to order_url(@order) and return
    else
      flash[:notice] = "Please create an account or login so we can associate this order with an account"
      session[:return_to] = "#{order_url(@order)}?payer_id=#{@order.pagseguro_payment.payer_id}"
      redirect_to signup_path
    end
  end
end