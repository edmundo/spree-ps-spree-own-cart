# PagSeguro Carrinho Próprio (spree-ps-spree-own-cart)
Extensão que fornece suporte ao sistema brasileiro de pagamentos online PagSeguro utilizando o carrinho próprio do Spree.

## Instalação
      script/extension install git://github.com/edmundo/spree-ps-spree-own-cart.git

## Como funciona
Esta extensão foi baseada na extensão pp_website_standard (suporte ao PayPal Website Payment Standard) desenvolvida pelo Gregg Pollack, portanto funciona de forma bastante similar sobrepondo a finalização padrão do pedido de forma que ela seja enviada a um gateway externo e finalizada diretamente fora do site pela interface web do gateway. Na finalização do pedido fica visível o botão customizado indicando que o pedido será enviado ao PagSeguro.

## Funcionalidades
* Envio do pedido de compra ao PagSeguro (isso é o mínimo que essa extensão deve fazer).
* Posicionada após as etapas de preenchimento de informações de envio (endereço e frete) para que já sejam incluídas no pedido e enviadas ao PagSeguro.
* Processamento, validação (incluindo suporte a token) e registro de notificações.
* Acompanhamento do estado do pagamento incluindo o histórico de notificações recebidas através da interface administrativa juntamente com as informações do pedido.

## Estado atual
Em desenvolvimento.

## Pendente
Possibilitar a configuração do tipo de frete (cálculo próprio, PAC calculado pelo PagSeguro, Sedex calculado pelo PagSeguro) através da interface gráfica.
Fazer a interface de testes ficar mais parecida com o servidor do PagSeguro.
Testar em produção (já que o PagSeguro não tem servidor de testes).

## Configuração
Não é necessário "escolher" o PagSeguro como forma de pagamento já que a finalização padrão está sendo sobreposta. Você pode configurar a sua conta utilizada no PagSeguro acessando as configurações da extensão através do módulo administrativo.

#gems necessários
activerecord-tableless

#Screenshots

Exemplos de funcionalidades acessíveis através da interface, (a customização do layout não está incluída).

Acompanhamento do estado dos pedidos
<br/><br/>
<img src="http://i498.photobucket.com/albums/rr350/edmundo_vn/spree-ps-spree-own-cart_orders_list.png" style="border: 1px solid #CCC;" />

Acompanhamento do estado do pagamento e notificações recebidas
<br/><br/>
<img src="http://i498.photobucket.com/albums/rr350/edmundo_vn/spree-ps-spree-own-cart_payment_txns.png" style="border: 1px solid #CCC;" />

## Testes
O sistema tem algumas ações que respondem com respostas pré-definidas imitando o servidor do PagSeguro, você pode rodar duas instâncias do sistema e fazer uma utilizar a outra como servidor de testes, esse é o padrão. Ou você pode fazer o download do ambiente de testes em http://visie.com.br/pagseguro/ambientetestes.php. Conforme as instruções, você deve rodá-lo e ele ficará disponível localmente na porta 443. Eu particularmente não altero o arquivo /etc/hosts, a extensão tenta utilizar automaticamente a url de testes como gateway de pagamento se você setar a opção "Sempre utilizar o servidor de testes" ou rodar o sistema em modo de desenvolvimento.

## Agradecimentos
Ao Gregg Pollack por ter publicado a extensão pp_website_standard e ter me poupado bastante trabalho.

## Diagramas de Estado (ilustrando as mudanças efetuadas)
Original
<br/><br/>
<a href="http://i498.photobucket.com/albums/rr350/edmundo_vn/original_states_100.png">
  <img src="http://i498.photobucket.com/albums/rr350/edmundo_vn/original_states_30.png" style="border: 1px solid #CCC;" />
</a>

Alterado
<br/><br/>
<a href="http://i498.photobucket.com/albums/rr350/edmundo_vn/pagseguro_states_100.png">
  <img src="http://i498.photobucket.com/albums/rr350/edmundo_vn/pagseguro_states_30.png" style="border: 1px solid #CCC;" />
</a>

