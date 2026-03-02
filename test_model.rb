require 'rumale'
require 'numo/narray'

def predict_price(params)
  model = Marshal.load(File.read("house_model.dat"))

  input = Numo::DFloat[[
    params[:area],
    params[:rooms],
    params[:bathrooms],
    params[:age]
  ]]

  puts "Predict price: #{model.predict(input)[0]}K"
end

predict_price(area: 500, rooms: 10, bathrooms: 5, age: 20)
