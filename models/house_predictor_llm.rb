require 'ruby_llm'
require 'dotenv/load'
require_relative 'house_predictor'

class HousePredictorLLM < RubyLLM::Tool
  desc "Predicts Las Vegas house price based on construction year, lot square feet, calculated acres, land value, improvement value, and zipcode"

  def execute(construction_year:, lot_sqft:, calc_acres:, land_value:, improvement_value:, zipcode:)
    _calc_acres = calc_acres.to_f < 1 ? 0.0 : calc_acres.to_f

    price = HousePredictor.instance.predict(
      construction_year: construction_year.to_i,
      lot_sqft: lot_sqft.to_f,
      calc_acres: _calc_acres,
      land_value: land_value.to_f,
      improvement_value: improvement_value.to_f,
      zipcode: zipcode.to_i
    )

    {
      construction_year: construction_year.to_i,
      lot_sqft: lot_sqft.to_f,
      calc_acres: _calc_acres,
      land_value: land_value.to_f,
      improvement_value: improvement_value.to_f,
      zipcode: zipcode.to_i,
      predicted_price: price
    }
  rescue => e
    { error: e.message }
  end
end
