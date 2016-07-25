require 'sinatra'

VALIDATION_TOKEN = "dc3aab2a-3c08-4d76-a590-7e61a7a7a80a".freeze

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
    puts messaging_event
    messaging_event["entry"].first["messaging"].each do |msg|
      puts msg
      sender = msg["sender"]["id"]
      if msg["message"] && msg["message"]["text"]
        payload = msg["postback"]["payload"]
        puts "Sender ID: #{sender}, Text: #{payload}"
      end
    end
end

# def payload(sender, payload)
#   data = {
#     recipient: { id: sender },
#     message: payload
#   }
#   send_message(data)
# end
