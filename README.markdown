# PagSeguro Carrinho Próprio (spree-ps-spree-own-cart)
Extensão que fornece suporte ao sistema brasileiro de pagamentos online PagSeguro utilizando o carrinho próprio do Spree.

## ATENÇÃO! O DESENVOLVIMENTO DESTA EXTENSÃO FOI DESCONTINUADO
Após vários mêses de desenvolvimento, em 05/10/2009 foi efetuada uma venda com a finalidade de testar o serviço do
PagSeguro (autenticação PagSeguro ECD6F78C-3B83-4481-B7B4-539AA81D085A), aceitando o pagamento de um produto pessoal
do autor desta extensão através do sistema de pagamento do
PagSeguro no valor de R$ 460,20. Nesta mesma época foi tentada a retirada deste valor para uma conta bancária,
no entanto ao invés do valor ter sido pago como devido, o valor simplesmente foi bloqueado pelo PagSeguro e não foi
pago.
Após vários contatos por telefone e protocolos de atendimento, ninguém soube informar o motivo do bloqueio do dinheiro.
Foram feitas várias reclamações através do sistema de contato do PagSeguro, reclamações no site reclameaqui, contatos
para intermediação através da associação Pró-Teste (especializada em defesa do consumidor) incluindo o envio de um
comunicado extra judicial solicitando a resolução do problema.
Atualmente passados já 6 meses do ocorrido, uma das respostas que eu obtive do PagSeguro é que "NÃO HÁ PRAZO PARA RESOLUÇÃO
DO PROBLEMA", indicando uma total falta de respeito e de integridade da empresa, que simplesmente está de posse de um valor
que não é seu. Não executando nem mesmo o propósito a qual ela se destina que seria de intermediar pagamentos aos seus
clientes.

A relação atual entre o autor da extensão e a empresa PagSeguro infelizmente está se encaminhando para um processo
judicial.

Tendo em vista o ocorrido, informo que o desenvolvimento desta extensão está encerrado e não é sugerida nem encorajada a
integração com o PagSeguro pelo autor, a extensão constará apenas como referência
caso alguém tenha interesse de olhar o código-fonte.


## Instalação
      script/extension install git://github.com/edmundo/spree-ps-spree-own-cart.git

## Como funciona
Esta extensão foi baseada na extensão `pp_website_standard` (suporte ao PayPal Website Payment Standard) desenvolvida pelo Gregg Pollack, portanto funciona de forma bastante similar sobrepondo a finalização padrão do pedido de forma que ela seja enviada a um gateway externo e finalizada diretamente fora do site pela interface web do gateway. Na finalização do pedido fica visível o botão customizado indicando que o pedido será enviado ao PagSeguro.

## Funcionalidades
* Envio do pedido de compra ao PagSeguro (isso é o mínimo que essa extensão deve fazer).
* Posicionada após as etapas de preenchimento de informações de envio (endereço e frete) para que já sejam incluídas no pedido e enviadas ao PagSeguro.
* Possibilidade de atualização manual dos estados do pagamento se for necessário.
* Processamento, validação (incluindo suporte a token) e registro de notificações.
* Atualização automática do estado do pedido de acordo com a aprovação do pagamento (inclusive por notificações).
* Acompanhamento do estado do pagamento incluindo o histórico de notificações recebidas através da interface administrativa juntamente com as informações do pedido.

## Estado atual
Em desenvolvimento.

## Código mantido dentro do diretório app a ser mixado
Atualmente não estou colocando o código dentro do arquivo `..._extension.rb` utilizando `class_eval`, favor dar uma olhada nos últimos commits aqui `http://github.com/edmundo/spree/tree/app_override` para fazer o código de dentro do `app` ser mixado automaticamente.

## Pendente
* Corrigir problemas de troca de conjunto de caracteres (o PagSeguro utiliza ISO-8859-1 enquanto o Spree utiliza UTF-8).
* Incluir a possibilidade de adicionar anotações aos pagamentos.
* Incluir a possibilidade de criar pagamentos manualmente caso tenham sido feitos fora do processo de compra para
  fazer o pagamento de qualquer valor não previsto.
* Possibilitar a configuração do tipo de frete (cálculo próprio, PAC calculado pelo PagSeguro, Sedex calculado pelo PagSeguro) através da interface gráfica.
* Fazer a interface de testes ficar mais parecida com o servidor do PagSeguro.
* Testar em produção (já que o PagSeguro não tem servidor de testes).

## Configuração
Não é necessário "escolher" o PagSeguro como forma de pagamento já que a finalização padrão está sendo sobreposta. Você pode configurar a sua conta utilizada no PagSeguro acessando as configurações da extensão através do módulo administrativo.

#gems necessários
* `activerecord-tableless`

#Screenshots

Exemplos de funcionalidades acessíveis através da interface, (a customização do layout não está incluída).

Acompanhamento do estado dos pedidos

![](http://i498.photobucket.com/albums/rr350/edmundo_vn/spree-ps-spree-own-cart_orders_list.png)

Acompanhamento do estado do pagamento e notificações recebidas

![](http://i498.photobucket.com/albums/rr350/edmundo_vn/spree-ps-spree-own-cart_payment_txn.png)

## Testes
O sistema tem algumas ações que respondem com respostas pré-definidas imitando o servidor do PagSeguro, a extensão tenta utilizar automaticamente a url de testes como gateway de pagamento se você setar a opção "Sempre utilizar o servidor de testes" ou rodar o sistema em modo de desenvolvimento.

## Agradecimentos
Ao Gregg Pollack por ter publicado a extensão `pp_website_standard` e ter me poupado bastante trabalho.

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

