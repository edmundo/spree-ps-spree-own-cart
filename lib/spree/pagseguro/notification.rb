require 'net/http'

module Spree #:nodoc:
  module Pagseguro #:nodoc:
    class Notification
      include PostsData
      
      attr_accessor :params
      attr_accessor :raw
      
      # set this to an array in the subclass, to specify which IPs are allowed to send requests
      class_inheritable_accessor :production_ips

      def initialize(post, options = {})
        @options = options
        empty!
        parse(post)
      end

      def status
        raise NotImplementedError, "Must implement this method in the subclass"
      end

      # the money amount we received in X.2 decimal.
      def gross
        raise NotImplementedError, "Must implement this method in the subclass"
      end

      def gross_cents
        (gross.to_f * 100.0).round
      end

      # This combines the gross and currency and returns a proper Money object. 
      # this requires the money library located at http://dist.leetsoft.com/api/money
      def amount
        return Money.new(gross_cents, currency) rescue ArgumentError
        return Money.new(gross_cents) # maybe you have an own money object which doesn't take a currency?
      end

      # reset the notification. 
      def empty!
        @params  = Hash.new
        @raw     = ""      
      end
      
      # Check if the request comes from an official IP
      def valid_sender?(ip)
        return true if ActiveMerchant::Billing::Base.integration_mode == :test || production_ips.blank?
        production_ips.include?(ip)
      end
      

      
      #######################



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
      private

      # Take the posted data and move the relevant data into a hash
      def parse(post)
        @raw = post.to_s
        for line in @raw.split('&')    
          key, value = *line.scan( %r{^([A-Za-z0-9_.]+)\=(.*)$} ).flatten
          params[key] = CGI.unescape(value)
        end
      end

    end
  end
end
