Rails.application.routes.draw do
  # ------------------------------------------------------------
  # Health check
  # ------------------------------------------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  # ------------------------------------------------------------
  # Authentication
  # ------------------------------------------------------------
  get    "/login",  to: "sessions#new",     as: :login
  delete "/logout", to: "sessions#destroy", as: :logout

  get "/auth/:provider/callback", to: "sessions#create"
  get "/auth/failure", to: redirect("/")
  post "/discord_login", to: redirect("/auth/discord"), as: :discord_login
  get "/microsoft_login", to: redirect("/auth/microsoft_graph"), as: :microsoft_login

  # ------------------------------------------------------------
  # Public CMS
  # ------------------------------------------------------------
  root "home#index"

  resources :pages,    only: [:index, :show]
  resources :posts,    only: [:index, :show]
  resources :services, only: [:index, :show]
  resources :events,   only: [:index, :show], param: :slug
  resources :categories, only: [:show]
  resources :tags,       only: [:show]
  resources :comments,   only: [:create]

  resources :contact_messages, only: [:new, :create]

  resources :giveaways, only: [:show] do
    resources :entries, only: [:create]

    member do
      post :join
    end

  end

  resources :bingo_cards, only: [:show] do
    member do
      post :mark_cell
      post :claim_win
    end
  end


  # ------------------------------------------------------------
  # Theme switching (optional, CMS-level)
  # ------------------------------------------------------------
  post "set_theme", to: "themes#set_theme", as: :set_theme

  # ------------------------------------------------------------
  # Admin
  # ------------------------------------------------------------
  namespace :admin do
    root "dashboard#index"
    get "coffer", to: "coffer#index", as: :coffer
    post 'inject_currency', to: 'coffer#inject_currency'

  resources :giveaways do
      member do
        patch :close # Locks entries
        patch :draw  # Secretly filters and picks winner
      end
      
      resources :giveaway_entries, only: [:index, :destroy]
    end

    resources :pending_actions, only: [:index, :update] do
        collection do
          patch :bulk_approve
        end
      end

    resources :pages do
      member do
        patch :update_category
        delete "remove_image/:signed_id", action: :remove_image, as: :remove_image
      end
    end

    resources :bingo_games do
      collection do
        get :overlay
      end
      member do
        post :start
        post :end
      end
    end

    resources :bingo_items
    resources :bingo_cards
    resources :posts
    resources :sections do
      member do
        patch :move_up
        patch :move_down
      end

      resources :blocks, except: [:index, :show] do
        member do
          patch :move_up
          patch :move_down
        end
      end
    end

    resources :categories
    resources :tags
    resources :menus do
      resources :menu_items do
        member do
          patch :move_up
          patch :move_down
          patch :update_parent
        end
      end
    end

    resources :media do
      collection do
        get :screenshots
      end

      member do
        patch :approve
      end
    end

    resources :downloads
    resources :events
    resources :services
    resources :testimonials
    resources :comments

    resources :users, only: [:index, :show, :edit, :update] do
      member do
        post :toggle_giveaway_ban
      end
    end

    resources :settings
    resources :contact_messages, only: [:index, :show]
  end


  # ------------------------------------------------------------
  # Catch-all CMS pages (LAST)
  # ------------------------------------------------------------
  get "/:slug", to: "pages#show", as: :catch_all_page
end
