require 'sinatra'
require 'json'
require 'uri'
require 'net/http'

VALIDATION_TOKEN = "dc3aab2a-3c08-4d76-a590-7e61a7a7a80a".freeze
PAGE_ACCESS_TOKEN = 'EAADpxMcwG4wBABKQfiXDApHTaQUI78iFu3cZBPZCjVlqnAR0so6RHNq1R8G0c6YTFgQZBbs8uAl1waKZAbsyGOPm8tbn2uZAZAecUXZAApeif305TcFMoaq5iTdkgqkl2R1GQVf2Jcfe3Vp64unZBOnJZA9VQZAZBZAmPaY4ZADyF2su2XAZDZD'.freeze

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


post '/callback' do
  messaging_event = JSON.parse(request.body.read)
  messaging_event
  messaging_event["entry"].first["messaging"].each do |msg|
    msg
    sender = msg["sender"]["id"]
    if msg["message"] && msg["message"]["text"]
      handel_requst(msg["message"]["text"], sender)
    else
      handel_requst('something', sender)
    end

  end
end

def handel_requst(text, sender)
  case text
  when 'hi' || 'Hi'
    payload(sender, text)
  else
    payload(sender, "don't understand")
  end
end

def send_message(message, sender)
  uri = URI('https://graph.facebook.com/v2.6/me/messages')
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)

  request["access_token"] = PAGE_ACCESS_TOKEN
  request["HEADER2"] = 'VALUE2'

  response = https.request(request)
  puts response
end

def payload(sender, payload)
  data = {
    recipient: { id: sender },
    message: payload
  }
  send_message(data)
end
