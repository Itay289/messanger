require 'sinatra'
require 'json'
require 'httparty'

VALIDATION_TOKEN = "dc3aab2a-3c08-4d76-a590-7e61a7a7a80a".freeze
PAGE_ACCESS_TOKEN = 'EAADpxMcwG4wBAObiLuEOQDdYGWznvM20mb2xWcSHY1YawC8P9ifa4D43VX3ECFlikZAaGJkzQNicdcKPOEroZCeiI0t1ECDj7f32vGmnnElZBRsmB3P0fpl2bOkvWAqq8wpxdUkbZA2EOTP73uaxVwZBVVg9tHxy6NxuO1GWsggZDZD'.freeze

USERS = [{
          id: '1092457560847217', 
          teams: ['arsenal', 'barca']
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
  get_started = get_started_message
  request_body = JSON.parse(request.body.read)
  messaging_events = request_body["entry"][0]["messaging"]
  messaging_events.each do |event|
    logger.info("#{event}")
    sender = event["sender"]["id"]
    postback = event["postback"]["payload"] if event["postback"]
    if !event["message"].nil? && !event["message"]["text"].nil?
      text = event["message"]["text"]
      bot_response(sender, text, postback)
    end
  end

  status 200
  body ''
end

get "/send_message" do
  USERS.each do |user|
    sender = user[:id]
    text = params['text'] || nil
    user[:teams].each do |team|
      push_message(sender, team, text)
    end  
  end
  status 200 
end

def push_message(sender, team, text)
  request_endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{PAGE_ACCESS_TOKEN}"
  request_body = team_post_message(sender, team, text)

  HTTParty.post(request_endpoint, :body => request_body, :headers => { 'Content-Type' => 'application/json' } )
end

def bot_response(sender, text, postback=nil)
  request_endpoint = "https://graph.facebook.com/v2.6/me/messages?access_token=#{PAGE_ACCESS_TOKEN}"
  logger.info("#{postback}")
  request_body =  if postback.present?
                    text_message_request_body(sender, "Welcome to 90min bot")
                  else      
                    response_manager(sender, text)
                  end

  HTTParty.post(request_endpoint, :body => request_body, :headers => { 'Content-Type' => 'application/json' } )
end

def response_manager(sender, text)
  case text.downcase
  when 'hello'
    text_message_request_body(sender, 'Hello, what team do you want to follow')
  when 'hi'
    text_message_request_body(sender, text)
  when *teams; text
    team_post_message(sender, text)
  else
    text_message_request_body(sender, "Please type team's name")
  end
end

def teams
  ['arsenal', 'manchester united', 'real madrid', 'barca', 'barcelona']
end

def get_started_message
  request_endpoint = "https://graph.facebook.com/v2.6/me/thread_settings?access_token=#{PAGE_ACCESS_TOKEN}"
  request_body = 
  { 
    "setting_type":"call_to_actions",
    "thread_state":"new_thread",
    "call_to_actions":[
        {
         "payload":"USER_DEFINED_PAYLOAD"
        }
      ]
    }.to_json 
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

def team_post_message(sender, team, text=nil)
  title = text ||= "#{team} news"
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
            title: title,
            subtitle: "#{team}",
            item_url: "https://www.90min.com/teams/#{team}",               
            image_url: "http://static.minutemediacdn.com/assets/production/icons/teams/h50/#{team}.png",
            buttons: [{
              type: "web_url",
              url: "https://www.90min.com/teams/#{team}",
              title: "Open Web URL"
            }], 
          }]
        }
      }
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
