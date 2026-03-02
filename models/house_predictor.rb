require 'rumale'
require 'numo/narray'
require 'singleton'

class HousePredictor
  include Singleton

  def initialize
    model_path = File.join(File.dirname(__FILE__), '..', 'house_model.dat')
    @model = Marshal.load(File.read(model_path))
  end

  def predict(area:, rooms:, bathrooms:, age:)
    input = Numo::DFloat[[area.to_f, rooms.to_f, bathrooms.to_f, age.to_f]]
    @model.predict(input)[0].round(2)
  end
end