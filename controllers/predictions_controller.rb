require_relative '../models/house_predictor'

class PredictionsController
  def initialize
    @predictor = HousePredictor.instance
  end

  def index
    { view: :index, locals: {} }
  end

  def predict(params)
    area      = params[:area] || params["area"]
    rooms     = params[:rooms] || params["rooms"]
    bathrooms = params[:bathrooms] || params["bathrooms"]
    age       = params[:age] || params["age"]

    price = @predictor.predict(
      area: area.to_f,
      rooms: rooms.to_f,
      bathrooms: bathrooms.to_f,
      age: age.to_f
    )

    {
      view: :result,
      locals: {
        area: area,
        rooms: rooms,
        bathrooms: bathrooms,
        age: age,
        price: price
      }
    }
  rescue => e
    {
      view: :index,
      locals: {
        error_message: e.message
      }
    }
  end
end