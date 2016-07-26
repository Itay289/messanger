require 'sinatra'
require 'json'
require 'httparty'

VALIDATION_TOKEN = "dc3aab2a-3c08-4d76-a590-7e61a7a7a80a".freeze
PAGE_ACCESS_TOKEN = 'EAADpxMcwG4wBAK9JVJqF42Gidc66qabh1mxZB4i2UF7q2ydHI4fgbzxZAYWTO2O7JpOrph0lxd2ZAzcw8Rn1bNzcqTgjqxDZBnaeZBiGbfwujJPhgZCctHwnqJZBMkJU7dbvBWUZCqGAovsWBTqxH3dq7XaWYs0OoWSEpBonZCZAbhdwZDZD'.freeze

get '/' do
  "Hello World!"
end

get '/callback' do
  logger.info "#{params}"
  if params['hub.mode'] == 'subscribe' && params['hub.verify_token'] == VALIDATION_TOKEN
     
    params['hub.challenge']
  else
    403
  end  
end


post "/callback" do
  request_body = JSON.parse(request.body.read)
  messaging_events = request_body["entry"][0]["messaging"]
  messaging_events.each do |event|
    sender = event["sender"]["id"]
    logger.info "#{sender}"
    if !event["message"].nil? && !event["message"]["text"].nil?
      text = event["message"]["text"]
      bot_response(sender, text)
    end
  end

  status 201
  body ''
end

get "/send_message" do
  sender = '1092457560847217'
  text = params['text'] || 'Default'
  bot_response(sender, text)
  status 200
end

def bot_response(sender, text)
  request_endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{PAGE_ACCESS_TOKEN}"
  request_body = text_message_request_body(sender, text)

  HTTParty.post(request_endpoint, :body => request_body, :headers => { 'Content-Type' => 'application/json' } )
end

def text_message_request_body(sender, text)
  {
    recipient: {
      id: sender
    },
    message: {
      text: text
    }
  }.to_json
end

def response(text)
  text
end
