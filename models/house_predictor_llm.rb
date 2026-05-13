require 'ruby_llm'
require 'dotenv/load'
require_relative 'house_predictor'

class HousePredictorLLM < RubyLLM::Tool
  desc "Predicts house price based on area (square meters), number of rooms, number of bathrooms, and age (years)"

  def execute(area:, rooms:, bathrooms:, age:)
    price = HousePredictor.instance.predict(
      area: area.to_f,
      rooms: rooms.to_f,
      bathrooms: bathrooms.to_f,
      age: age.to_f
    )

    {
      area: area.to_f,
      rooms: rooms.to_f,
      bathrooms: bathrooms.to_f,
      age: age.to_f,
      predicted_price: price
    }
  rescue => e
    { error: e.message }
  end
end
