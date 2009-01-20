require 'net/http'

class Notification < ActiveRecord::Base
  include Spree::Pagseguro::PostsData
 
  has_no_table

  belongs_to :order
  
  column :VendedorEmail, :string
  column :TransacaoID, :string
  column :Referencia, :string
  column :TipoFrete, :string
  column :ValorFrete, :float
  column :Anotacao, :string
  column :DataTransacao, :string
  column :TipoPagamento, :string
  column :StatusTransacao, :string
  column :CliNome, :string
  column :CliEmail, :string
  column :CliEndereco, :string
  column :CliNumero, :string
  column :CliComplemento, :string
  column :CliBairro, :string
  column :CliCidade, :string
  column :CliEstado, :string
  column :CliCEP, :string
  column :CliTelefone, :string
  column :NumItens, :string

  # Define some columns dynamically.
  (1..25).to_a.each do |i|
    ["ProdID_#{i}", "ProdDescricao_#{i}"].each do |item|
      column item.to_sym, :string
    end
    column "ProdQuantidade_#{i}".to_sym, :integer
    ["ProdValor_#{i}", "ProdFrete_#{i}", "ProdExtras_#{i}"].each do |item|
      column item.to_sym, :float
    end
  end

  validates_inclusion_of :TipoFrete, :in => ["FR", "SD", "EN"], :message => "%s não está incluído na lista"
  validates_inclusion_of :TipoPagamento, :in => ["Pagamento", "Cartão de Crédito", "Boleto", "Pagamento online"], :message => "%s não está incluído na lista"
  validates_inclusion_of :StatusTransacao, :in => ["Completo", "Aguardando Pagto", "Aprovado", "Em Análise", "Cancelado"], :message => "%s não está incluído na lista"

  validates_format_of :CliCEP, :with => /\A[0-9]{8}\Z/i, :message => "%s deve conter exatamente oito dígitos numéricos sem o traço"

  validates_numericality_of :NumItens, :only_integer => true, :message => I18n.translate('is_not_an_integer')
  validates_numericality_of :NumItens, :greater_than_or_equal_to => 1, :message => I18n.translate('is_not_a_positive_number')

#  (1..25).to_a.each do |i|
#    validates_numericality_of "ProdQuantidade_#{i}".to_sym
#    validates_numericality_of "ProdValor_#{i}".to_sym
#    validates_numericality_of "ProdFrete_#{i}".to_sym
#    validates_numericality_of "ProdExtras_#{i}".to_sym
#  end

  validates_presence_of :order, :message => "não foi possível estabelecer um vínculo com pedido algum."
  
  def validate
    # Validates if it is unique.
    unless transaction_id_unique?
      errors.add(:TransacaoID, :error_message_taken)
    end
    # Validates if the seller e-mail is correct.
    unless self.VendedorEmail == Spree::Pagseguro::Config[:account]
      errors.add(:VendedorEmail, "não é nosso endereço de e-mail.")
    end
    # Validates totals.
    if order
      # Calculate the notification totals.
      self.items_price = 0
      self.items_shipping_price = 0
      self.items_extras = 0
      (1..self.NumItens.to_i).to_a.each do |i|
        self.items_price += self.send("ProdValor_#{i}") * self.send("ProdQuantidade_#{i}")
        self.items_shipping_price += self.send("ProdFrete_#{i}")
        self.items_extras += self.send("ProdExtras_#{i}")
      end
      self.items_total = self.items_price + self.items_shipping_price + self.items_extras
      # Verify if the total order value in the notification is the same as in the order.
      unless self.items_total == self.order.total
        errors.add(:order, "total não confere com a notificação, pedido: #{self.order.total}, notificação: #{self.items_total}.")
      end
    end
  end

  attr_accessor :raw
  attr_accessor :items_price
  attr_accessor :items_shipping_price
  attr_accessor :items_extras
  attr_accessor :items_total

  
  def complete?
    StatusTransacao == "Completo"
  end

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

  # Parse the post and fill the model.
  def parse!(post)
    # Set the source raw post received.
    @raw = post.to_s
    
    # Parse it.
    for line in @raw.split('&')    
      key, value = *line.scan( %r{^([A-Za-z0-9_.]+)\=(.*)$} ).flatten
      temp = CGI.unescape(value)
      
      # Fix delimiters if necessary.
      temp.gsub!(/\D/,'.') if key.include?("ProdValor_")
      temp.gsub!(/\D/,'.') if key.include?("ProdFrete_")
      temp.gsub!(/\D/,'.') if key.include?("ProdExtras_")
      temp.gsub!(/\D/,'.') if key == "ValorFrete"
      
      self.send("#{key}=", temp) if self.respond_to?(key.to_s)
    end
    
    # Define to wich order it points to.
    self.order = Order.find_by_number(self.Referencia)

    # Define the shipping type as defined by the store if nothing was received.
    self.TipoFrete = "FR" if self.TipoFrete.nil? || self.TipoFrete.empty? 
    
    return true
  end
  
  def transaction_id_unique?
    PagseguroTxn.find_by_transaction_id(self.TransacaoID) == nil
  end

  def empty?
    raw.empty?
  end

end
