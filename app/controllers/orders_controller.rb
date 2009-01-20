class OrdersController < Spree::BaseController
#  before_filter :associate_order, :only => :show
#
#  private
#  def associate_order
#    return unless payer_id = params[:payer_id]
#    orders = Order.find(:all, :include => :pagseguro_payment, :conditions => ['pagseguro_payments.payer_id = ? AND orders.user_id is null', payer_id])
#    orders.each do |order|
#      order.update_attribute("user", current_user)
#    end
#  end

  before_filter :set_charset, :only => :transmit
  def set_charset
    headers["Content-Type"] = "text/html; charset=ISO-8859-1"
  end

  include Spree::Pagseguro::PostsData

  before_filter :load_object, :only => [:checkout, :confirmation, :transmit, :finished]
  skip_before_filter :verify_authenticity_token, :only => [:transmit]

#      skip_before_filter :verify_authenticity_token, :only => [:confirmation]

  def confirmation
    # Mark the order as "ready to transmit"
    if @order.state == "shipment"
      @order.next!
    end

  end

  def transmit
    require 'iconv'

    if Spree::Pagseguro::Config[:always_use_sandbox] || RAILS_ENV == 'development'
      pagseguro_url = Spree::Pagseguro::Config[:sandbox_billing_url]
    else
      pagseguro_url = Spree::Pagseguro::Config[:billing_url]
    end

    # Mark the order as waiting for payment response if it was ready to transmit and clean the session.
    if @order.state == "ready_to_transmit"
      @order.wait_for_payment_response!

      @order.update_attribute("ip_address", request.env['REMOTE_ADDR'] || "unknown")
      @order.update_attribute("checkout_complete", true)

      # Get rid of the order in the session quick and put it in another place just for the
      # final message.
      session[:transmited_order_id] = session[:order_id]
      session[:order_id] = nil
    end

    render :layout => false
  end

  def finished
    # Here is just rendered the finish message.
  end

end