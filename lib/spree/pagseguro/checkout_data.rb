require 'erb'
require 'cgi'

module Spree #:nodoc:
  module Pagseguro #:nodoc:
    module CheckoutData
      def data_to_send(order)
        data_to_transmit = {
          "email_cobranca" => Spree::Pagseguro::Config[:account],
          "tipo"           => "CP",
          # Necessary only if using the calculation from the gateway.
          # "tipo_frete"     => "FR",
          "moeda"          => "BRL",
          "cliente_nome"   => order.address.full_name,
          "cliente_cep"    => order.address.zipcode,
          "cliente_end"    => order.address.address1,
          "cliente_num"    => "",
          "cliente_compl"  => order.address.address2,
          "cliente_bairro" => "",
          "cliente_cidade" => order.address.city,
          "cliente_uf"     => order.address.state_text,
          "cliente_pais"   => "BRA",
          "cliente_ddd"    => "",
          "cliente_tel"    => order.address.phone,
          "cliente_email"  => "",
          "ref_transacao"  => order.number.to_s
        }
          
        order.line_items.each_with_index do |item, index|
          data_to_transmit.merge!(
            "item_id_#{index + 1}"    => item.variant.sku,
            "item_descr_#{index + 1}" => item.variant.product.name,
            "item_quant_#{index + 1}" => item.quantity.to_s,
            "item_valor_#{index + 1}" => (item.price*100).to_i.to_s
          )
          if index == 0
            data_to_transmit.merge!("item_frete_#{index + 1}" => order.ship_amount.to_s.gsub(/\D/,''))
          else
            data_to_transmit.merge!("item_frete_#{index + 1}" => "0")
          end
        end

        string = data_to_transmit.map {|k,v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}" }.join('&')
      end
    
      module_function :data_to_send
    end
  end
end
