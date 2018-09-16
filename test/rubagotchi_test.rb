ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "rack/test"
require_relative "../rubagotchi"

Minitest::Reporters.use!

class RubagotchiTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def session
    last_request.env["rack.session"]
  end

  def pet_session
    pet = new_pet
    yield(pet) if block_given?
    { "rack.session" => { pet: pet } }
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, '<img src="/images/main.gif" />'
  end

  def test_food_redirect_when_sleeping
    get "/food", {}, pet_session { |pet| pet[:sleep] = true }

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet is sleeping!", session[:message]
  end

  def test_food_redirect_when_messy
    get "/food", {}, pet_session { |pet| pet[:messy] = true }

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet is messy!", session[:message]
  end

  def test_food_redirect_when_sick
    get "/food", {}, pet_session { |pet| pet[:sick] = true }

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet is sick!", session[:message]
  end

  def test_food_redirect_when_full
    get "/food", {}, pet_session { |pet| pet[:hunger] = 0 }

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet is full!", session[:message]
  end

  def test_food_eat
    post "/food/eat", { food: 'ice-cream' }, pet_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, '<img src="/images/ice-cream.gif" />'
  end

  def test_info_view
    get "/info", {}, pet_session

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_doctor_view
    get "/doctor", {}, pet_session { |pet| pet[:sick] = true }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, '<img src="/images/doctor.gif" />'
    assert_includes last_response.body, '<form method="post" action="/doctor">'
  end

  def test_doctor_redirect_when_well
    get "/doctor", {}, pet_session

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet isn't sick!", session[:message]
  end

  def test_doctor_post
    post "/doctor", {}, pet_session { |pet| pet[:sick] = true }

    assert_equal 302, last_response.status
    assert_equal false, session[:pet][:sick]
  end

  def test_bathroom_view
    get "/bathroom", {}, pet_session { |pet| pet[:messy] = true }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, '<img src="/images/bathroom.gif" />'
    assert_includes last_response.body, '<form method="post" action="/bathroom">'
  end

  def test_bathroom_redirect_when_clean
    get "/bathroom", {}, pet_session

    assert_equal 302, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal "Pet isn't messy!", session[:message]
  end

  def test_sleep_redirect_when_messy
    post "/sleep", {}, pet_session { |pet| pet[:messy] = true }
    assert_equal 302, last_response.status
    assert_equal "Can't sleep now!", session[:message]
  end

  def test_sleep_redirect_when_messy
    post "/sleep", {}, pet_session { |pet| pet[:sick] = true }
    assert_equal 302, last_response.status
    assert_equal "Can't sleep now!", session[:message]
  end

  def test_go_to_sleep
    post "/sleep", { sleep: true }, pet_session
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal true, session[:pet][:sleep]
    assert_includes last_response.body, "main-sleep.gif"
  end

  def test_wake_up
    post "/sleep", { sleep: false }, pet_session { |pet| pet[:sleep] = true }
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_equal false, session[:pet][:sleep]
    assert_includes last_response.body, "main.gif"
  end

  def test_help
    get "/help"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<p>Check your pet's hunger and happiness"
    assert_includes last_response.body, '<p>Feed your pet some'
    assert_includes last_response.body, '<p>Take your pet to the'
  end
end
