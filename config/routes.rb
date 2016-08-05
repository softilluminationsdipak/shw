# TODO: Cleanup after rails3 upgrade script
Eripme::Application.routes.draw do

  get "leads/index"

  require 'sidekiq/web'
  # ...
  mount Sidekiq::Web, at: '/sidekiq'
  
  match '/current_active_statuses' => 'claims#current_active_statuses'  
  match '/generate-key' => 'partners#generate_api_key', :as => :generate_api_key, :via => :post
  devise_for :partners, :path => "affiliate", :controllers => {:registrations => "partner/registrations", :sessions => "partner/sessions"}, :skip => [:passwords]
  match '/affiliates', to: 'partners#index'
  match 'auth_token', to: 'partners#auth_token',       as: 'partner_auth_token'
  match 'token_destroy/:id', to: 'partners#token_destroy', as: 'token_destroy'
  match 'auth/:provider/callback', to: 'partner/facebook#create'
  match 'auth/failure', to: redirect('/')
  match 'signout',    to: 'partner/facebook#destroy', as: 'signout'
  match 'my_account', to: 'partners#my_account', as: 'my_account'
  match 'my_account/update/(:id)', to: 'partners#update', as: 'update_my_account'
  match 'change_password', to: 'partners#change_password', as: 'change_password'
  
  match '/reload_content/:id' => "admin/content#reload_content", :as => :reload_content
  match '/content/async_save' => "admin/content#async_save", :as => :async_save_content
  match '/create-content' => 'admin/content#async_create', :as => :async_create_content

  match 'login' => 'admin/admin#login', :as => :login
  match 'billing' => 'site#billing', :as => :billing, :via => [:get, :post]
  match '/purchase' => 'site#purchase', :as => :purchase, :via => [:get, :post]
  match '/error'  => 'shw#error', :as => :error, :via => [:get, :post ]
  match '/validate_state_name' => 'site#validate_state_name', :as => :validate_state_name, :via => [:get, :post]
  
  match 'admin/content/async_get_package_prices' => 'admin/content#async_get_package_prices', :via => [:get, :post]
  match '/admin/discounts/async_validate' => 'admin/discounts#async_validate', :via => [:get, :post]
  match '/revert_to_new_without_ci' => 'admin/customers#revert_to_new_without_ci', :via => [:get, :post]
  match '/change_status' => 'admin/customers#change_status', :via => [:get, :post]
  match '/admin/search_customer' => 'admin/customers#search_customer', :as => :search_customer, :via => [:get]

  match '/claims/active_statuses' => 'admin/claims#current_active_statuses', :as => :claim_current_active_statuses, :via => [:get]
  post '/admin/customers/update_credit_card_to_non_admin/:id', to: 'admin/customers#update_credit_card_to_non_admin', as: 'update_credit_card_to_non_admin'
  
  match 'contract/:id' => 'admin/customers#contract', :as => :contract_pdf, :format => 'pdf'
  match 'admin/customers/contract/:id' => 'admin/customers#contract', :format => 'pdf'

  match 'admin/setting' => 'admin/settings#settings', :via => [:get, :post]
  # affiliate home page, new added
  namespace :admin do
    resources :leads, :only => [:index, :show]
  end
  match '/:controller(/:action(/:id))', :controller => /admin\/[^\/]+/

  match '/admin/transactions/authorize_silent_post', :as => :authorize_silent_post, :via => :post
  match '/affiliate(/:discountcode)'  => 'site#affiliate', :as => :affiliate

  match '/admin/customers/nmi_payment/:id' => 'admin#customers/nmi_payment', :as => :admin_nmi_payment
  
  match '/admin/subscriptions/nmi_billing/:id' => 'admin#subscriptions/nmi_billing', :as => :admin_subscription_nmi_billing
  match '/admin/subscriptions/manual_billing/:id' => 'admin#subscriptions/manual_billing', :as => :admin_subscription_manual_billing

  match '/admin/subscriptions/delete_subscription/:id' => 'admin#subscriptions/delete_subscription', :as => :admin_subscription_delete_subscription
  match '/admin/subscriptions/refund/:id' => 'admin#subscriptions/refund', :as => :admin_subscription_refund
  match '/admin/subscriptions/void_transaction/:transaction_id' => 'admin#subscriptions/void_transaction', :as => :void_transaction
  resources :sub_affilates
  #match '/submitclaim' => 'admin/contractors#submitclaim'
  namespace :admin do
    resources :leads, :only => [:index, :show]
    resources :submitclaim, :only => [:index]
    match '/contractor/:id/update_status' => "contractors#update_status"
    match '/retricted' => 'admin#retriction'
    match '/contractor/:id/update_status' => "contractors#update_status"
    match '/notes/update_note_reference' => "notes#update_note_reference"
    match '/notes/:note_id/attachment/download' => "notes#download_note_attachment", :as => :download_note_attachment
    match '/add_claim_notes' => 'claims#add_claim_notes'
    match '/generate_pdf_for_buy_out/(:claim_id)' => 'claims#generate_pdf_for_buy_out'
    match '/select-unselect-status/(:type)'  => 'claims#select_and_unselect_statues', :as => :select_unselect_status
    match 'customers/edit/:id.print'        => 'customers#edit', :print => true
    match 'authenticate'                    => 'admin#authenticate'
    match ':action'                         => 'admin#index'
    root :to => "admin#index"
    match 'customer_statuses'               => 'customer_statuses#index'
    match 'permissions'                     => 'permission#index'
    match 'ipaddresses'                     => 'ipaddresses#index'
    match 'claim_statuses'                  => 'claim_statuses#index'
    match 'lead_statuses'                   => 'lead_statuses#index'
    match 'result_statuses'                 => 'result_statuses#index'
    match 'tag_statuses'                    => 'tag_statuses#index'
    match 'contract_statuses'               => 'contract_statuses#index'
    match 'renewal_statuses'                => 'renewal_statuses#index'
    match 'contractor_statuses'             => 'contractor_statuses#index'
    match 'cancellation_reasons'            => 'cancellation_reasons#index'
    match 'fax_sources'                     => 'fax_sources#index'
    match '/change-customer-status/:type/:id'   => 'customer_statuses#disable'
    match '/change-claim-status/:type/:id'      => 'claim_statuses#disable'
    match '/change-contractor-status/:type/:id' => 'contractor_statuses#disable'
    match '/admin/customers/edit/:id/#notes'         => 'customers#edit', :as => :customer_edit_note
    match '/admin/states'                     => 'states#index'
    #match '/admin/merchant_accounts'          => 'merchant_accounts#index'
    match '/gateways'          => 'gateways#index'
    match '/sub-affiliates/new'               => 'affiliates#new',      :via => :get, :as => :new_sub_affiliates
    match '/sub-affiliates/index'             => 'affiliates#index',    :via => [:get, :post], :as => :list_sub_affiliates
    match '/sub-affiliates/create'            => 'affiliates#create',   :via => :post
    match '/sub-affiliates/destroy/:id'       => 'affiliates#destroy',  :via => [:delete, :get]
    match '/sub-affiliates/edit/:id'          => 'affiliates#edit',     :via => :get
    match '/sub-affiliates/update/:id'        => 'affiliates#update',   :via => :put

    resources :reports, :only => [:index] do
      collection do
        get 'customer_report'
        get 'missing_renewal_dates'
        get 'income_sources'
        get 'lead_by_agent'
        get 'affiliate_and_leads'
        get 'performance_report'
      end
    end
  end

  match '/:controller(/:action(/:id))'

  scope :constraints => { :protocol => 'https'} do
    match '/quote' => 'site#quote'  
    match '/purchase' => 'site#purchase'
    match '/billing' => 'site#billing'
  end
  
  # match ':action' => 'site'
  match '/plans' => 'site#plans'
  match '/sites/plans' => 'site#plans'
  match '/homeownercenter'  => 'shw#homeownercenter'
  match '/buyingandselling' => 'shw#buyingandselling'
  match '/realestate'       => 'shw#realestate'
  match '/contractors'      => 'shw#contractors'
  match '/termsconditions'  => 'shw#termsconditions'
  match '/contact'          => 'shw#contact'
  match '/about'            => 'shw#about'
  match '/faq'              => 'shw#faq'
  match '/api_doc'          => 'shw#api_doc'
  match '/lead_api_doc'     => 'shw#lead_api_doc'
  match '/testimonials'     => 'shw#testimonials'
  match '/request_thankyou' => 'shw#request_thankyou', :via => :post
  match '/partner_portal' => 'shw#affiliate_portal'
  match '/submitclaim' => 'site#submitclaim'
  scope :protocol => 'https://', :constraints => { :protocol => 'https://' } do
    match '/quote'          => 'site#quote' 
  end
  
  root :to => 'shw#index'

  ## site
  match '/restricted_state' => 'site#restricted_state', :via => :get, :as => :restricted_state
  match '/please_call'      => 'site#please_call',      :via => :get, :as => :please_call

  ## Below routes is use for API
  namespace :api, :defaults => {:format => 'json'} do
    scope :module => :v1 do
      ## This routes is for : Posting Data on "Get a Quote" using API
      post 'customers/create'  => 'customers#add_customer_for_get_a_quote'      
      post 'leads/create'  => 'customers#generate_lead'
    end
  end

  match "*path" => redirect("/")
end

