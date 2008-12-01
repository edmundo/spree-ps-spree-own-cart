require 'net/http'

module Spree #:nodoc:
  module Pagseguro #:nodoc:
    class Notification
      include PostsData
      
      attr_accessor :params
      attr_accessor :raw
      
      # set this to an array in the subclass, to specify which IPs are allowed to send requests
      class_inheritable_accessor :production_ips

      # Define some methods dynamically.
      (1..25).to_a.each do |i|
        [
          ["prod_id_#{i}", "ProdId_#{i}"],
          ["prod_description_#{i}", "ProdDescricao_#{i}"],
          ["prod_quantity_#{i}", "ProdQuantidade_#{i}"]
        ].each do |item|
          define_method(item[0]) { params[item[1]] }
        end
        define_method("prod_price_#{i}") { params["ProdValor_#{i}"].gsub(/\D/,'').to_f / 100 }
        define_method("prod_shipping_price_#{i}") { params["ProdFrete_#{i}"].gsub(/\D/,'').to_f / 100 }
        define_method("prod_extras_#{i}") { params["ProdExtras_#{i}"].gsub(/\D/,'').to_f / 100 }
      end

      def initialize(post, options = {})
        @options = options
        empty!
        parse(post)
      end

      # reset the notification. 
      def empty!
        @params  = Hash.new
        @raw     = ""      
      end
      
      def seller_email
        params['VendedorEmail']
      end

      def transaction_id
        params['TransacaoID']
      end

      def reference
        params['Referencia']
      end

      def shipping_type
        params['TipoFrete']
      end

      def shipping_price
        params['ValorFrete'].gsub(/\D/,'').to_f / 100
      end
      
      def notes
        params['Anotacao']
      end

      def received_at
        params['DataTransacao']
      end

      def payment_type
        params['TipoPagamento']
      end

      def transaction_status
        params['StatusTransacao']
      end

      def client_name
        params['CliNome']
      end

      def client_email
        params['CliEmail']
      end

      def client_adress1
        params['CliEndereco']
      end

      def client_number
        params['CliNumero']
      end

      def client_adress2
        params['CliComplemento']
      end

      def client_borough
        params['CliBairro']
      end

      def client_city
        params['CliCidade']
      end

      def client_state
        params['CliEstado']
      end

      def client_zip
        params['CliCEP']
      end

      def client_phone
        params['CliTelefone']
      end
      
      def complete?
        transaction_status == "Completo"
      end

      def number_of_items
        params['NumItens']
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
      def acknowledge(token)
        if Spree::Pagseguro::Config[:always_use_sandbox] || RAILS_ENV == 'development'
          pagseguro_url = Spree::Pagseguro::Config[:sandbox_verification_url]
        else
          pagseguro_url = Spree::Pagseguro::Config[:verification_url]
        end

        payload = raw

        new_payload = "Comando=validar&Token=#{token}&" + payload
        if Spree::Pagseguro::Config[:always_use_sandbox] || RAILS_ENV == 'development'
          response = post(pagseguro_url, new_payload, 'Content-Length' => "#{new_payload.size}")
        else
          response = ssl_post(pagseguro_url, new_payload, 'Content-Length' => "#{new_payload.size}")
        end
        raise StandardError.new("Faulty pagseguro result: #{response}") unless ["VERIFICADO", "FALSO"].include?(response)

        response == "VERIFICADO"
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
