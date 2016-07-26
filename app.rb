require 'sinatra'
require 'json'
require 'httparty'

VALIDATION_TOKEN = "dc3aab2a-3c08-4d76-a590-7e61a7a7a80a".freeze
PAGE_ACCESS_TOKEN = 'EAADpxMcwG4wBAObiLuEOQDdYGWznvM20mb2xWcSHY1YawC8P9ifa4D43VX3ECFlikZAaGJkzQNicdcKPOEroZCeiI0t1ECDj7f32vGmnnElZBRsmB3P0fpl2bOkvWAqq8wpxdUkbZA2EOTP73uaxVwZBVVg9tHxy6NxuO1GWsggZDZD'.freeze

USERS = [{
          id: '1092457560847217', 
          teams: ['arsenal']
        }]

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
    if !event["message"].nil? && !event["message"]["text"].nil?
      text = event["message"]["text"]
      bot_response(sender, text)
    end
  end

  status 200
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
  request_body = response_manager(sender, text)

  HTTParty.post(request_endpoint, :body => request_body, :headers => { 'Content-Type' => 'application/json' } )
end

def response_manager(sender, text)
  case text
  when 'hello' || 'Hello'
    text_message_request_body(sender, 'Hello, what team do you want to follow')
  when 'hi'
    text_message_request_body(sender, text)
  when *teams; text
    text_message_request_body(sender, "You will now get notifications from '#{text}'")
  else
    logger.info "#{generic_message(sender)}"
    generic_message(sender)
  end
end

def teams
  ['arsenal', 'manchester united', 'real madrid', 'barca', 'barcelona']
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

def generic_message(sender)
  {
    recipient: {
      id: sender
    },
    message: {
      attachment: {
        type: "template",
        payload: {
          template_type: "generic",
          elements: [{
            title: "arsenal news",
            subtitle: "arsenal",
            item_url: "https://www.90min.com/teams/arsenal",               
            image_url: "http://static.minutemediacdn.com/assets/production/icons/teams/h50/arsenal.png",
            buttons: [{
              type: "web_url",
              url: "https://www.90min.com/teams/arsenal",
              title: "Open Web URL"
            }], 
          }]
        }
      }
    }
  }.to_json
end

def user_exists?(sender) 
  USERS.any? {|user| user[:id].include?(sender)}
end
