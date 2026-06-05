require 'rumale'
require 'numo/narray'
require 'csv'

# Load data from CSV file
data = CSV.read("housing_las_vegas_06_22_26.csv", headers: true)

# Extract features and target
houses_features = data.map do |row|
  [
    row['CONSTYR'].to_i,      # Construction year
    row['LOTSQFT'].to_i,      # Lot square feet
    row['CALC_ACRES'].to_f,   # Calculated acres
    row['LANDVAL1'].to_i,     # Land value
    row['IMPVAL'].to_i,       # Improvement value
    row['ZIPCODE'].to_i       # Zipcode
  ]
end

houses_prices = data.map { |row| row['SALEPRICE'].to_i }

# Features:
# [construction_year, lot_sqft, calc_acres, land_value, improvement_value, zipcode]
x = Numo::DFloat.asarray(houses_features)

# Sale prices
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
