require 'rumale'
require 'numo/narray'
require 'singleton'

class HousePredictor
  include Singleton

  def initialize
    model_path = File.join(File.dirname(__FILE__), '..', 'house_model.dat')
    @model = Marshal.load(File.read(model_path))
  end

  def predict(construction_year:, lot_sqft:, calc_acres:, land_value:, improvement_value:, zipcode:)
    input = Numo::DFloat[[
      construction_year,
      lot_sqft.to_f,
      calc_acres.to_f,
      land_value.to_f,
      improvement_value.to_f,
      zipcode
    ]]
    @model.predict(input)[0].round(2)
  end
end
