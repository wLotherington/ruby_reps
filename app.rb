require 'sinatra'
require 'sinatra/reloader'
require 'open3'
require 'byebug'

require_relative 'db/database.rb'
require_relative 'models/user.rb'
require_relative 'lib/sm2.rb'

configure do
  enable :sessions
end

helpers do
  def logged_in?
    !!current_user
  end

  def admin?
    session[:user_role] == 'admin' && logged_in?
  end

  def current_user
    session[:username]
  end
end

before do
  @db = DB.new
end

after do
  @db.disconnect
end

# ---------- TOP LEVEL ----------

get '/' do
  @center = true
  
  if logged_in?
    redirect '/reps'
  else
    erb :home
  end
end

get '/instructions' do
  erb :instructions
end

get '/about' do
  erb :about
end

# ---------- USERS ----------

# users#index
get '/users' do
  #do user list
    # ADMIN ONLY
    # list all users
    # potentially allow chainging permissions
end

# users#new
get '/register' do
  @user = User.new
  erb :register
end

# users#create
post '/register' do
  @user = User.new(params, @db)

  if @user.save
    login(@user)

    redirect '/reps'
  else
    erb :register
  end
end

# ---------- SESSION ----------

# session#new
get '/login' do
  @user = User.new
  erb :login
end

# session#create
post '/login' do
  @user = User.new(params, @db)

  if @user.valid_login?
    login(@user)

    redirect '/reps'
  else
    erb :login
  end
end

get '/finished' do
  erb :finished
end

# session#destroy
get '/logout' do
  logout
end

# ---------- CARDS ----------

# cards#index
get '/cards' do
  #do card list
    # ADMIN ONLY?
end

# cards#new
get '/cards/new' do
  @center = true
  erb :create_cards
end

# cards#create
post '/cards' do
  # ADMIN ONLY
  card_data = JSON.parse(request.body.read)
  card = @db.cards_create(card_data)

  card.to_json
end

# cards#show
get 'cards/:id' do
  #do load card page
    # ADMIN ONLY
end

# cards#edit
get 'cards/:id/edit' do
  #do edit card page
    # ADMIN ONLY
end

# cards#update
put '/cards/:id' do
  card = JSON.parse(request.body.read)
  q = ['Again', 'Hard', 'Good', 'Easy']

  quality = q.index(card['quality'])
  sm2 = Sm2.new(quality)

  card['next_repetition_date'] = sm2.next_repetition_date
  card['interval'] = sm2.interval
  card['easiness_factor'] = sm2.easiness_factor

  @db.reps_update(card, session[:user_id]);

  card['next_repetition_date'] = sm2.next_repetition_date
  card['interval'] = sm2.interval
  card['easiness_factor'] = sm2.easiness_factor

  card.to_json
end

# cards#destroy
delete '/cards/:id' do
  #do delete card
    # ADMIN ONLY
end

# ---------- REPS ----------

# reps#index
get '/reps' do
  @center = true
  if logged_in?
    erb :reps
  else
    redirect '/'
  end
end


get '/reps/all' do
  reps = @db.reps_all(session[:user_id])

  {reps: reps}.to_json
end

# reps#edit
get '/reps/:id/edit' do
  #do show rep page
end

# reps#update
put '/reps/:id' do
  #do update rep record
end

# reps#script
post '/script' do
  script = JSON.parse(request.body.read)['code']
  file_path = 'public/scripts/script.rb'

  open(file_path, 'w') { |f|
    f.puts "return_value = ("
    f.puts script
    f.puts ")"
    f.puts "p return_value"
  }

  return_value, stderr, status = Open3.capture3("ruby " + file_path)

  stderr.empty? ? return_value.split("\n").last : 'ERROR'
end

# ---------- INVITES ----------

# invites#index
get '/invites' do
  #do show all invites
    # ADMIN ONLY
    # show which users used each one
    # show expiration date
end

# invites#new
get '/invites/new' do
  #do create new invite form
    # ADMIN ONLY
    # invite key
    # expiration date
end

#invites#create
post '/invites' do
  #do create new invite code record
    # ADMIN ONLY
end

# invites#edit
get '/invites/:id/edit' do
  #do invite edit page
    # ADMIN ONLY
end

# invites#update
put '/invites/:id' do
  #do update invite
end

private

def login(user)
  session[:username] = user.username
  session[:user_id] = user.id
  session[:user_role] = user.role
end

def logout
  session[:username] = nil
  session[:user_id] = nil
  session[:user_role] = nil
end