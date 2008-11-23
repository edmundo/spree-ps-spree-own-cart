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
      
#      # Check if the request comes from an official IP
#      def valid_sender?(ip)
#        return true if ActiveMerchant::Billing::Base.integration_mode == :test || production_ips.blank?
#        production_ips.include?(ip)
#      end
      

      
      #######################

#      t.string :client_name
#      t.string :client_email
#      t.string :client_adress1
#      t.string :client_number
#      t.string :client_adress2
#      t.string :client_bairro
#      t.string :client_city
#      t.string :client_state
#      t.string :client_zip
#      t.string :client_phone

      def seller_email
        params['VendedorEmail']
      end

      def reference
        params['Referencia']
      end

      def transaction_id
        params['TransacaoID']
      end

      def transaction_status
        params['StatusTransacao']
      end

      def client_email
        params['CliEmail']
      end
      
      def shipping_type
        params['TipoFrete']
      end

      def shipping_price
        params['ValorFrete'].to_d
      end
      
      def complete?
        status == "Completo"
      end

      def received_at
        params['DataTransacao']
      end

      def extra
        params['X']
      end

      def notes
        params['Anotacao']
      end

      def payment_type
        params['TipoPagamento']
      end

      def number_of_items
        params['NumItems']
      end

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
