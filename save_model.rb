require 'rumale'
require 'numo/narray'

# Load data from CSV file
data = CSV.read("houses.csv")
houses_features = data.map { |row| (0..row.length-2).map { |i| row[i].to_i } }
houses_prices = data.map { |row| row.last.to_i }

# Features:
# [area, rooms, bathrooms, age]
x = Numo::DFloat.asarray(houses_features)

# Prices corresponding to the features (in thousands)
y = Numo::DFloat.asarray(houses_prices)

model = Rumale::Ensemble::RandomForestRegressor.new(
  n_estimators: 100,
  max_depth: nil,
  random_seed: 42
)

model.fit(x, y)

File.open("house_model.dat", "wb") do |f|
  Marshal.dump(model, f)
end
