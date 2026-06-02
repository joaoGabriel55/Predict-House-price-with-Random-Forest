require 'ruby_llm'
require 'dotenv/load'
require_relative 'house_predictor'

class HousePredictorLLM < RubyLLM::Tool
  desc "Predicts Las Vegas house price based on construction year, lot square feet, calculated acres, land value, improvement value, and zipcode"

  def execute(construction_year:, lot_sqft:, calc_acres:, land_value:, improvement_value:, zipcode:)
    price = HousePredictor.instance.predict(
      construction_year: construction_year.to_f,
      lot_sqft: lot_sqft.to_f,
      calc_acres: calc_acres.to_f,
      land_value: land_value.to_f,
      improvement_value: improvement_value.to_f,
      zipcode: zipcode.to_f
    )

    {
      construction_year: construction_year.to_f,
      lot_sqft: lot_sqft.to_f,
      calc_acres: calc_acres.to_f,
      land_value: land_value.to_f,
      improvement_value: improvement_value.to_f,
      zipcode: zipcode.to_f,
      predicted_price: price
    }
  rescue => e
    { error: e.message }
  end
end
