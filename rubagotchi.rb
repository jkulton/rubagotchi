require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "date"
require "time"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def new_pet
  {
    hunger: 3,
    happiness: 3,
    poop: false,
    sleep: false,
    sick: false,
    birthday: DateTime.now.to_s,
    hunger_timer: DateTime.now.to_s
  }
end

def main_display_screen
  return 'main-sick' if @pet[:sick]
  return 'main-messy' if @pet[:messy]
  return 'main-sleep' if @pet[:sleep]
  return 'main-happy' if @pet[:happiness] == 5
  'main'
end

def should_get_messy?
  [true, false].sample
end

def should_get_sick?
  [false, false, false, false, true].sample
end

def should_increment_hunger?
  now = Time.new
  last_hunger = Time.parse(session[:pet][:hunger_timer])
  seconds_in_hour = 3600
  hunger_counter = ((now - last_hunger) / seconds_in_hour).to_i
  hunger_counter > 0
end

def hours_old
  current_time = DateTime.now
  birthday = DateTime.parse(session[:pet][:birthday])
  ((current_time - birthday) * 24).to_i
end

def days_old
  hours_old / 24
end

def clear_hunger_timer
  session[:pet][:hunger_timer] = DateTime.now.to_s
end

def increment_hunger
  session[:pet][:hunger] += 1 if session[:pet][:hunger] < 5
  session[:pet][:happiness] -= 1 if session[:pet][:happiness] > 0
  clear_hunger_timer
end

def eat
  session[:pet][:hunger] -= 1 if session[:pet][:hunger] > 0
  session[:pet][:happiness] += 1 if session[:pet][:happiness] < 5
end

def redirect_home(message='')
  if block_given? && yield
    session[:message] = message
    redirect "/"
  end
end

before do
  session[:pet] ||= new_pet
  @pet = session[:pet]
  increment_hunger if should_increment_hunger?
end

get "/" do
  @screen = main_display_screen
  erb :main
end

get "/food" do
  redirect_home("Pet is sleeping!") { @pet[:sleep] }
  redirect_home("Pet is messy!") { @pet[:messy] }
  redirect_home("Pet is sick!") { @pet[:sick] }
  redirect_home("Pet is full!") { @pet[:hunger].zero? }
  erb :food
end

post "/food/eat" do
  session[:pet][:messy] = should_get_messy?
  session[:pet][:sick] = should_get_sick?
  eat
  clear_hunger_timer
  erb :eat
end

get "/info" do
  erb :info
end

get "/doctor" do
  redirect_home("Pet isn't sick!") { !@pet[:sick] }
  erb :doctor
end

post "/doctor" do
  session[:pet][:sick] = false
  redirect "/"
end

get "/bathroom" do
  redirect_home("Pet isn't messy!") { !@pet[:messy] }
  erb :bathroom
end

post "/bathroom" do
  session[:pet][:messy] = false
  redirect "/"
end

post "/sleep" do
  redirect_home("Can't sleep now!") { @pet[:messy] || @pet[:sick] }
  should_sleep = params[:sleep] == 'true' ? true : false
  session[:pet][:sleep] = should_sleep
  redirect "/"
end

get "/help" do
  erb :help
end
