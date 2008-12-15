require 'erb'
require 'cgi'

module Spree #:nodoc:
  module Pagseguro #:nodoc:
    module CheckoutData
      def data_to_send(order)
#        data_to_transmit = {
#          "email_cobranca" => truncate(h(Spree::Pagseguro::Config[:account]), 200),
#          "tipo"           => "CP",
#          "moeda"          => "BRL",
#          "cliente_nome"   => truncate(h(order.address.full_name), 100),
#          "cliente_cep"    => truncate(h(order.address.zipcode), 8),
#          "cliente_end"    => truncate(h(order.address.address1), 200),
#          "cliente_num"    => truncate(h('123'), 10),
#          "cliente_compl"  => truncate(h(order.address.address2), 100),
#          "cliente_bairro" => truncate(h('teste') ,100),
#          "cliente_cidade" => truncate(h(order.address.city), 100),
#          "cliente_uf"     => truncate(h(order.address.state_text), 2),
#          "cliente_pais"   => "BRA",
#          "cliente_ddd"    => "51",
#          "cliente_tel"    => truncate(h(order.address.phone), 8),
#          "cliente_email"  => truncate(h('teste@teste.com'), 200),
#          "ref_transacao"  => truncate(h(order.number.to_s), 200)
#        }
#          
#        order.line_items.each_with_index do |item, index|
#          data_to_transmit.merge!(
#            "item_id_#{index + 1}"    => truncate(item.variant.product.sku, 100),
#            "item_descr_#{index + 1}" => truncate(item.variant.product.name, 100),
#            "item_quant_#{index + 1}" => truncate(item.quantity.to_s, 3),
#            "item_valor_#{index + 1}" => truncate((item.price*100).to_i.to_s, 7)
#          )
#          if index == 0
#            data_to_transmit.merge!("item_frete_#{index + 1}" => truncate(@cost.to_s.gsub(/\D/,''), 7))
#          else
#            data_to_transmit.merge!("item_frete_#{index + 1}" => "0")
#          end
#        end
#          
#        string = data_to_transmit.map {|k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }.join('&')


        data_to_transmit = {
          "email_cobranca" => Spree::Pagseguro::Config[:account],
          "tipo"           => "CP",
          "moeda"          => "BRL",
          "cliente_nome"   => order.address.full_name,
          "cliente_cep"    => order.address.zipcode,
          "cliente_end"    => order.address.address1,
          "cliente_num"    => '123',
          "cliente_compl"  => order.address.address2,
          "cliente_bairro" => 'teste',
          "cliente_cidade" => order.address.city,
          "cliente_uf"     => order.address.state_text,
          "cliente_pais"   => "BRA",
          "cliente_ddd"    => "51",
          "cliente_tel"    => order.address.phone,
          "cliente_email"  => 'teste@teste.com',
          "ref_transacao"  => order.number.to_s
        }
          
        order.line_items.each_with_index do |item, index|
          data_to_transmit.merge!(
            "item_id_#{index + 1}"    => item.variant.product.sku,
            "item_descr_#{index + 1}" => item.variant.product.name,
            "item_quant_#{index + 1}" => item.quantity.to_s,
            "item_valor_#{index + 1}" => (item.price*100).to_i.to_s
          )
          if index == 0
            data_to_transmit.merge!("item_frete_#{index + 1}" => @cost.to_s.gsub(/\D/,''))
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
