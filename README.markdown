# PagSeguro Carrinho Próprio (spree-ps-spree-own-cart)

Extensão que fornece suporte ao sistema brasileiro de pagamentos online PagSeguro utilizando o carrinho próprio do Spree.

## Instalação

        script/extension install git://github.com/edmundo/spree-ps-spree-own-cart.git

## Como funciona

Esta extensão foi baseada na extensão pp_website_standard (suporte ao PayPal Website Payment Standard) desenvolvida pelo Gregg Pollack, portanto funciona de forma bastante similar sobrepondo a finalização padrão do pedido de forma que ela seja enviada a um gateway externo e finalizada diretamente fora do site pela interface web do gateway. Na finalização do pedido fica visível o botão customizado indicando que o pedido será enviado ao PagSeguro.

## Configuração

Não é necessário "escolher" o PagSeguro como forma de pagamento já que a finalização padrão está sendo sobreposta. Você pode configurar a sua conta utilizada no PagSeguro acessando as configurações da extensão através do módulo administrativo.

## Testes

Favor fazer o download do ambiente de testes em http://visie.com.br/pagseguro/ambientetestes.php. Conforme as instruções, você deve rodá-lo e ele ficará disponível localmente na porta 443. Eu particularmente não altero o arquivo /etc/hosts, a extensão tenta utilizar automaticamente https://localhost como gateway de pagamento se você setar a opção "Sempre utilizar o servidor de testes" ou rodar o sistema em modo de desenvolvimento.

## Agradecimentos

Ao Gregg Pollack por ter publicado a extensão pp_website_standard e ter me poupado bastante trabalho.
