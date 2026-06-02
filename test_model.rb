require 'rumale'
require 'numo/narray'

def predict_price(params)
  model = Marshal.load(File.read("house_model.dat"))

  input = Numo::DFloat[[
    params[:construction_year],
    params[:lot_sqft],
    params[:calc_acres],
    params[:land_value],
    params[:improvement_value],
    params[:zipcode]
  ]]

  predicted_price = model.predict(input)[0]
  puts "Predicted price: $#{predicted_price.round(2)}"
end

# Example prediction with Las Vegas housing features
predict_price(
  construction_year: 2005,
  lot_sqft: 1500,
  calc_acres: 0.0,
  land_value: 28000,
  improvement_value: 65000,
  zipcode: 891290000
)
