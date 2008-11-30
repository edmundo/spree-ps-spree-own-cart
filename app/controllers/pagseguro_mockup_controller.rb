require 'digest/md5'

class PagseguroMockupController < Spree::BaseController
  skip_before_filter :verify_authenticity_token      
  layout 'empty'
  
  # Mocks https://pagseguro.uol.com.br/security/webpagamentos/webpagto.aspx
  def webpagto
    @transaction_id = Digest::MD5.hexdigest((0...20).map{65.+(rand(25)).chr}.join)

    # Receives the fields and shows 
    
  end

  # Mocks https://pagseguro.uol.com.br/CalculaFrete.aspx
  def calculafrete
    # Not implemented yet.
  end
  
  # Mocks https://pagseguro.uol.com.br/security/npi/default.aspx
  def default
    if params[:token] == Spree::Pagseguro::Config[:token]
      render :text => "VERIFICADO"
    else
      render :text => "FALSO"
    end    
  end
  
end
