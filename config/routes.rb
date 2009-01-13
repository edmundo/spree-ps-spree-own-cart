# Put your extension routes here.

map.resource :pagseguro_payment, :member => {:notification => :post}
map.resources :orders, :member => {:confirmation => :get, :transmit => :post, :finished => :get}

map.namespace :admin do |admin|
  admin.resource :pagseguro_settings
end
