require 'net/http'

module Spree #:nodoc:
  module Pagseguro #:nodoc:
    class Notification < ActiveMerchant::Billing::Integrations::Notification
      include ActiveMerchant::PostsData
      
      # Was the transaction complete?
      def complete?
        status == "Completo"
      end

      # When was this payment received by the client. 
      # sometimes it can happen that we get the notification much later. 
      # One possible scenario is that our web application was down. In this case paypal tries several 
      # times an hour to inform us about the notification
      def received_at
        params['DataTransacao']
        #Time.parse params['payment_date']
      end

      # Status of transaction. List of possible values:
      # <tt>Canceled-Reversal</tt>::
      # <tt>Completed</tt>::
      # <tt>Denied</tt>::
      # <tt>Expired</tt>::
      # <tt>Failed</tt>::
      # <tt>In-Progress</tt>::
      # <tt>Partially-Refunded</tt>::
      # <tt>Pending</tt>::
      # <tt>Processed</tt>::
      # <tt>Refunded</tt>::
      # <tt>Reversed</tt>::
      # <tt>Voided</tt>::
      def status
        params['StatusTransacao']
      end

      # Id of this transaction (paypal number)
      def transaction_id
        params['TransacaoID']
      end

      # What type of transaction are we dealing with? 
      #  "cart" "send_money" "web_accept" are possible here. 
      def type
        params['TipoPagamento']
      end

#      # the money amount we received in X.2 decimal.
#      def gross
#        0
#        #params['mc_gross']
#      end
#
#      # the markup paypal charges for the transaction
#      def fee
#        0
#        #params['mc_fee']
#      end
#
#      # What currency have we been dealing with
#      def currency
#        "X"
#        #params['mc_currency']
#      end
#
#      # This is the item number which we submitted to paypal 
#      # The custom field is also mapped to item_id because PayPal
#      # doesn't return item_number in dispute notifications
#      def item_id
#        params['item_number'] || params['custom']
#      end
#
#      # This is the invoice which you passed to paypal 
#      def invoice
#        params['invoice']
#      end   
#
#      # Was this a test transaction?
#      def test?
#        params['test_ipn'] == '1'
#      end
#      
#      def account
#        params['business'] || params['receiver_email']
#      end

      # Acknowledge the transaction to paypal. This method has to be called after a new 
      # ipn arrives. Paypal will verify that all the information we received are correct and will return a 
      # ok or a fail. 
      # 
      # Example:
      # 
      #   def paypal_ipn
      #     notify = PaypalNotification.new(request.raw_post)
      #
      #     if notify.acknowledge 
      #       ... process order ... if notify.complete?
      #     else
      #       ... log possible hacking attempt ...
      #     end
      def acknowledge
        payload =  raw

        response = ssl_post(Paypal.service_url + '?cmd=_notify-validate', payload, 
          'Content-Length' => "#{payload.size}",
          'User-Agent'     => "Active Merchant -- http://activemerchant.org"
        )
        
        raise StandardError.new("Faulty paypal result: #{response}") unless ["VERIFIED", "INVALID"].include?(response)

        response == "VERIFIED"
      end
    end
  end
end
