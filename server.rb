require 'sinatra'
require_relative 'models/house_predictor'
require_relative 'controllers/predictions_controller'

set :port, 4567
set :bind, '0.0.0.0'
set :public_folder, File.join(__dir__, 'public')
set :views, File.join(__dir__, 'views')

controller = PredictionsController.new

get '/' do
  erb :index
end

post '/predict' do
  result = controller.predict(params)
  erb result[:view], locals: result[:locals]
end