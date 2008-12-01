class PagseguroConfiguration < Configuration

  # the url parameters should not need to be changed (unless pagseguro changes the api or something other major change)
  preference :billing_url, :string, :default => "https://pagseguro.uol.com.br/security/webpagamentos/webpagto.aspx"
  preference :shipping_url, :string, :default => "https://pagseguro.uol.com.br/CalculaFrete.aspx"
  preference :verification_url, :string, :default => "https://pagseguro.uol.com.br/security/npi/default.aspx"

  preference :sandbox_billing_url, :string, :default => "http://localhost:3001/pagseguro_mockup/webpagto"
  preference :sandbox_verification_url, :string, :default => "http://localhost:3001/pagseguro_mockup/default"
#  preference :sandbox_billing_url, :string, :default => "https://localhost/security/webpagamentos/webpagto.aspx"
#  preference :sandbox_verification_url, :string, :default => "https://localhost/security/npi/default.aspx"

  # these are just default preferences of course, you'll need to change them to something meaningful
  preference :account, :string, :default => "your_account@example.com"
  # always use the sandbox even when in production
  preference :always_use_sandbox, :boolean, :default => false

  # security token
  preference :token, :string, :default => "C3671EA724CC82A3D9AB2D4F887B61F2"
  
  validates_presence_of :name
  validates_uniqueness_of :name
end