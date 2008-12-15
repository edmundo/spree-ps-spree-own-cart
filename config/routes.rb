# Put your extension routes here.

map.resource :pagseguro_payment, :collection => {:notification => :post}
map.resources :orders, :member => {:confirmation => :get, :transmit => :post}

map.namespace :admin do |admin|
  admin.resource :pagseguro_settings
end
