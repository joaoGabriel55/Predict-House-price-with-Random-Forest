require_relative '../models/house_predictor'
require_relative '../models/house_parameter_extractor'

class PredictionsController
  def initialize
    @predictor = HousePredictor.instance
    @extractor = HouseParameterExtractor.new
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

  def llm_index
    { view: :llm_index, locals: {} }
  end

  def predict_with_llm(params)
    text = params[:description] || params["description"]

    raise "Please provide a house description" if text.nil? || text.strip.empty?

    extracted_params = @extractor.extract_parameters(text)

    price = @predictor.predict(
      area: extracted_params[:area],
      rooms: extracted_params[:rooms],
      bathrooms: extracted_params[:bathrooms],
      age: extracted_params[:age]
    )

    {
      view: :llm_result,
      locals: {
        area: extracted_params[:area],
        rooms: extracted_params[:rooms],
        bathrooms: extracted_params[:bathrooms],
        age: extracted_params[:age],
        price: price,
        original_text: text
      }
    }
  rescue => e
    {
      view: :llm_index,
      locals: {
        error_message: e.message,
        description: text
      }
    }
  end
end