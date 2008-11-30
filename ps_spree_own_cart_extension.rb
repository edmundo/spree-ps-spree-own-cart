# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class PsSpreeOwnCartExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/ps_spree_own_cart"

  def activate

    # Add a partial for PagSeguro Payment txns
    Admin::OrdersController.class_eval do
      before_filter :add_ps_own_cart_txns, :only => :show
      def add_ps_own_cart_txns
        @txn_partials << 'ps_own_cart_txns'
      end
    end
    
#    # Add a filter to the OrdersController so that if user is reaching us from an email link we can 
#    # associate the order with the user (once they log in)
#    OrdersController.class_eval do
#      before_filter :associate_order, :only => :show
#      private
#      def associate_order  
#        return unless payer_id = params[:payer_id]
#        orders = Order.find(:all, :include => :pagseguro_payment, :conditions => ['pagseguro_payments.payer_id = ? AND orders.user_id is null', payer_id])
#        orders.each do |order|
#          order.update_attribute("user", current_user)
#        end
#      end
#    end

    OrdersController.class_eval do
      edit.before {
        if Spree::Pagseguro::Config[:always_use_sandbox] || RAILS_ENV == 'development'
          @pagseguro_url = Spree::Pagseguro::Config[:sandbox_billing_url]
        else
          @pagseguro_url = Spree::Pagseguro::Config[:billing_url]
        end
        @order.edit!
      }
    end

    # add new events and states to the FSM
    fsm = Order.state_machines['state']  
    fsm.events["fail_payment"] = PluginAWeek::StateMachine::Event.new(fsm, "fail_payment")
    fsm.events["fail_payment"].transition(:to => 'payment_failure', :from => ['in_progress', 'payment_pending'])

    fsm.events["pend_payment"] = PluginAWeek::StateMachine::Event.new(fsm, "pend_payment")
    fsm.events["pend_payment"].transition(:to => 'payment_pending', :from => 'in_progress')    
    fsm.after_transition :to => 'payment_pending', :do => lambda {|order| order.update_attribute(:checkout_complete, true)}  

    fsm.events["pay"] = PluginAWeek::StateMachine::Event.new(fsm, "pay")
    fsm.events["pay"].transition(:to => 'paid', :from => ['payment_pending', 'in_progress'])
    fsm.after_transition :to => 'paid', :do => :complete_order  

    fsm.events["ship"].transition(:to => 'shipped', :from => 'paid')
    
    # add a PagSeguroPayment association to the Order model
    Order.class_eval do 
      has_one :pagseguro_payment
    end
  
    # Add support for internationalization to this extension.
    Globalite.add_localization_source(File.join(RAILS_ROOT, 'vendor/extensions/ps_spree_own_cart/lang/ui'))

    # Add the administration link. (Only as a placeholder)
    Admin::ConfigurationsController.class_eval do
      before_filter :add_ps_spree_own_cart_link, :only => :index
      def add_ps_spree_own_cart_link
        @extension_links << {:link => admin_pagseguro_settings_path , :link_text => Globalite.localize(:ext_ps_spree_own_cart), :description => Globalite.localize(:ext_ps_spree_own_cart_description)}
      end
    end
  end
end