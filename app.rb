$:.push File.expand_path("../lib", __FILE__)

require 'sinatra/base'
require 'sinatra/content_for'
require 'sinatra/cookies'
require 'sinatra/navigation_helpers'

require 'omniauth'
require 'omniauth-twitter'
require 'omniauth-gplus'
require 'cfoundry'

require 'sequel'
require 'json'

module CFControlPanel
  class App < Sinatra::Base

  	# use Rack::Flash
    helpers Sinatra::Cookies
    helpers Sinatra::ContentFor
    helpers Sinatra::NavigationHelpers

    enable :static, :sessions #, :inline_templates
    set :session_secret, ENV['SESSION_SECRET']
    set :app_file, __FILE__
    set :root, File.dirname(__FILE__)
    set :public_folder, File.dirname(__FILE__) + '/public'

    AUTH_EXCEPTIONS = %w{/auth /login /intro} # Allow viewing these pages without auth
    PROD_DB_URL = ENV['PROD_DB_URL']

    #use OmniAuth::Strategies::Twitter, 'Kp9THFHyOduYm3p8BrLQQ', 'f3kkG47FzMCvh45ee5ddBFwHW7QSzfb479z0JTehrR4'
    use OmniAuth::Strategies::GPlus, '666044362701.apps.googleusercontent.com', 'wv8C13cOwIhG-3KgqmV4ecP5'

    def initialize
      init_db
      require 'cf_control_panel/models'
      self.class.send :include, CFControlPanel::Models

      super
    end

    before do
      authenticate!
    end

    get '/auth/:provider/callback' do
      auth = request.env['omniauth.auth']
      acct_id = "#{params[:provider]}_#{auth["uid"]}"

      User.unrestrict_primary_key

      user = User.find_or_create(:id => acct_id, :email => auth["info"]["email"])
      session["user_id"] = user.id
      
      redirect '/'
    end

    get "/login/:provider/?" do
      redirect "/auth/#{params[:provider]}" 
    end

    get "/logout/?" do
      session[:user_id] = nil
      redirect '/'
    end

    get '/auth/failure' do
      erb :index
    end

    get "/" do
      erb :index
    end

    get "/login/?" do
      erb :login, :layout => :login_layout
    end

    get "/profile/?" do
      erb :profile
    end

    post '/accounts/add_new' do
      puts session.inspect
      user = User.find(:id => session[:user_id])

      client = CFoundry::Client.new params['endpoint']
      auth = nil

      begin
        auth = client.login params['username'], params['password']
      rescue CFoundry::Denied; end;

      Account.create(
        :name => params[:name],
        :auth_key => auth.auth_header,
        :endpoint => params[:endpoint],
        :user_id => session[:user_id]
      )

      redirect "/accounts"
    end

    get "/accounts/?" do
      accounts = current_user.accounts
      redirect "/accounts/#{accounts.first.id}/details" if (accounts.length > 0)

      erb :"/accounts/index", :locals => {:accounts => current_user.accounts}
    end

    get "/accounts/:id/details/?" do
      user = current_user
      account = find_account(params[:id].to_i)

      erb :"/accounts/details", :locals => {:accounts => user.accounts, :account => account}
    end

    get "/accounts/*" do
      erb :"/accounts/#{params[:splat].first}", :locals => {:accounts => current_user.accounts}
    end

    get "/organizations/?" do
      content_type 'application/json'
      account = find_account(params['account_id'].to_i)
      account.orgs_summary
    end

    :private

    def find_account(account_id)
      account = current_user.accounts.select { |x| x.id == account_id }.first
      halt 404 if account.nil?
      account
    end

    def current_user
      user = User.find(:id => session[:user_id])
      puts user
      user
    end

    def authenticate!   
      redirect "/login" if AUTH_EXCEPTIONS.select { |e| request.env["PATH_INFO"].start_with?(e) }.length == 0 and session[:user_id].nil?
    end

    def init_db
      # inspect ruby env
      @db = ENV['RUBY_ENV'] == 'production' ? Sequel.connect(PROD_DB_URL) : Sequel.sqlite('/tmp/cf.db')
      @db.loggers << Logger.new($stdout)

      Sequel.extension :migration
      Sequel::Migrator.apply(@db, './migrations/')
    end
  end

end