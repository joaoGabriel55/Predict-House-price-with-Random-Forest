#!/usr/bin/env ruby
# frozen_string_literal: true

# ============================================================================
# LLM vs Random Forest — Benchmark Experiments
# ============================================================================
#
# Prerequisites:
#   gem install rumale numo-narray csv json net-http
#
# Usage:
#   1. Set your API key:  export OPENROUTER_API_KEY="sk-or-..."
#   2. Make sure houses.csv exists in the same directory
#   3. Run: ruby benchmark_experiments.rb
#
# This script runs 4 experiments:
#   1. Accuracy comparison (MAE / RMSE)
#       MAE (Mean Absolute Error) and RMSE (Root Mean Square Error) are crucial metrics for evaluating regression models.
#   2. Latency comparison
#   3. Consistency (variance) test
#   4. Hybrid pipeline (LLM extraction + RF prediction)
#
# Output: prints results to STDOUT and saves a summary to benchmark_results.md
# ============================================================================

require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'benchmark'
require 'rumale'
require 'numo/narray'

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

API_KEY        = ENV.fetch('OPENROUTER_API_KEY') { abort 'Set OPENROUTER_API_KEY env var' }
API_URL        = 'https://openrouter.ai/api/v1/chat/completions'
MODEL          = 'anthropic/claude-opus-4.6' # Change to any model on OpenRouter
CSV_FILE       = 'housing_las_vegas_05_05_17.csv'
TEST_RATIO     = 0.2          # 20% of data for testing
CONSISTENCY_N  = 10           # number of repeated LLM calls per test case
RANDOM_SEED    = 42

# Feature columns to use for prediction
FEATURE_COLS   = ['bedrooms', 'full_bathrooms', 'half_bathrooms', 'size_sqft', 'lot_size']
TARGET_COL     = 'price'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def call_llm(prompt, max_tokens: 300, temperature: 1.0)
  uri  = URI(API_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 30

  body = {
    model: MODEL,
    max_tokens: max_tokens,
    messages: [{ role: 'user', content: prompt }],
    temperature: temperature
  }

  req = Net::HTTP::Post.new(uri)
  req['Content-Type']  = 'application/json'
  req['Authorization'] = "Bearer #{API_KEY}"
  req['HTTP-Referer']  = 'https://github.com/joaoGabriel55/Predict-House-price-with-Random-Forest'
  req['X-Title']       = 'RF vs LLM Benchmark'
  req.body = body.to_json

  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  res   = http.request(req)
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start

  parsed = JSON.parse(res.body)

  # OpenRouter uses OpenAI-compatible response format
  text = parsed.dig('choices', 0, 'message', 'content') || ''
  { text: text, latency: elapsed }
end

def extract_number(text)
  # Try to find a number that looks like a price (possibly with K suffix)
  match = text.match(/(\d[\d,_.]*)\s*[Kk]/)
  if match
    return match[1].gsub(/[,_]/, '').to_f
  end

  # Try plain number
  numbers = text.scan(/\d[\d,_.]*/).map { |n| n.gsub(/[,_]/, '').to_f }
  # Pick the largest number (most likely the price)
  numbers.max || 0.0
end

def mae(actual, predicted)
  actual.zip(predicted).sum { |a, p| (a - p).abs } / actual.size.to_f
end

def rmse(actual, predicted)
  mse = actual.zip(predicted).sum { |a, p| (a - p)**2 } / actual.size.to_f
  Math.sqrt(mse)
end

# ---------------------------------------------------------------------------
# Load & Split Data
# ---------------------------------------------------------------------------

puts "=" * 70
puts "Loading data from #{CSV_FILE}..."
puts "=" * 70

# Parse CSV with headers
csv_data = CSV.read(CSV_FILE, headers: true)

# Extract features and target, filtering out rows with missing values
data = csv_data.map do |row|
  features = FEATURE_COLS.map { |col| row[col].to_f }
  # Convert price to thousands (K) - prices are like "22e4" = 220000 = 220K
  price = row[TARGET_COL].to_f / 1000.0

  # Skip rows with invalid data
  next if features.any?(&:zero?) || price.zero?

  features + [price]
end.compact

puts "Loaded #{data.size} valid rows from #{csv_data.size} total rows"

# Shuffle and split
data.shuffle!(random: Random.new(RANDOM_SEED))

split_idx = (data.size * (1 - TEST_RATIO)).to_i
train_data = data[0...split_idx]
test_data  = data[split_idx..]

train_x = Numo::DFloat.asarray(train_data.map { |r| r[0..-2] })
train_y = Numo::DFloat.asarray(train_data.map { |r| r.last })

test_features = test_data.map { |r| r[0..-2].map(&:to_f) }
test_prices   = test_data.map { |r| r.last.to_f }

puts "Train: #{train_data.size} rows | Test: #{test_data.size} rows"
puts

# ---------------------------------------------------------------------------
# Train Random Forest
# ---------------------------------------------------------------------------

puts "Training Random Forest (100 estimators)..."
rf_train_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

model = Rumale::Ensemble::RandomForestRegressor.new(
  n_estimators: 100,
  max_depth: nil,
  random_seed: RANDOM_SEED
)
model.fit(train_x, train_y)

rf_train_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - rf_train_start
puts "Training done in #{rf_train_time.round(3)}s"
puts

# ============================================================================
# EXPERIMENT 1 — Accuracy Comparison (MAE & RMSE)
# ============================================================================

puts "=" * 70
puts "EXPERIMENT 1: Accuracy Comparison"
puts "=" * 70

# --- Random Forest predictions ---
rf_predictions = []
rf_latencies   = []

test_features.each do |features|
  input = Numo::DFloat[*features]
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  pred  = model.predict(input.expand_dims(0))[0]
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  rf_predictions << pred
  rf_latencies << elapsed
end

rf_mae  = mae(test_prices, rf_predictions)
rf_rmse = rmse(test_prices, rf_predictions)
puts "Random Forest — MAE: #{rf_mae.round(2)}K | RMSE: #{rf_rmse.round(2)}K"

# --- LLM predictions ---
llm_predictions = []
llm_latencies   = []

# Limit to 20 test cases to avoid excessive API calls
test_subset_size = [test_features.size, 20].min
puts "Running LLM predictions on #{test_subset_size} test cases (may take a few minutes)..."

test_features[0...test_subset_size].each_with_index do |features, i|
  bedrooms, full_bath, half_bath, sqft, lot_sqft = features
  total_bath = full_bath + (half_bath * 0.5)

  prompt = <<~PROMPT
    You are a Las Vegas house price estimator. Based on these features, predict the house price in thousands of dollars (K).
    Reply with ONLY a number followed by K. Example: 450K

    Property Features:
    - Bedrooms: #{bedrooms.to_i}
    - Bathrooms: #{total_bath.round(1)} (#{full_bath.to_i} full, #{half_bath.to_i} half)
    - Square Footage: #{sqft.to_i} sqft
    - Lot Size: #{lot_sqft.to_i} sqft

    Predicted price:
  PROMPT

  result = call_llm(prompt, max_tokens: 50)
  price  = extract_number(result[:text])

  llm_predictions << price
  llm_latencies << result[:latency]

  puts "  [#{i + 1}/#{test_subset_size}] Actual: #{test_prices[i].round(1)}K | LLM: #{price}K (#{result[:latency].round(2)}s)"
  sleep(0.5) # rate limiting
end

llm_mae  = mae(test_prices[0...test_subset_size], llm_predictions)
llm_rmse = rmse(test_prices[0...test_subset_size], llm_predictions)
puts
puts "LLM — MAE: #{llm_mae.round(2)}K | RMSE: #{llm_rmse.round(2)}K"
puts

# For fair comparison, recalculate RF metrics on same subset
rf_mae_subset  = mae(test_prices[0...test_subset_size], rf_predictions[0...test_subset_size])
rf_rmse_subset = rmse(test_prices[0...test_subset_size], rf_predictions[0...test_subset_size])

# ============================================================================
# EXPERIMENT 2 — Latency Comparison
# ============================================================================

puts "=" * 70
puts "EXPERIMENT 2: Latency Comparison"
puts "=" * 70

rf_avg_latency  = rf_latencies.sum / rf_latencies.size * 1000  # in ms
llm_avg_latency = llm_latencies.sum / llm_latencies.size * 1000 # in ms

puts "Random Forest — Avg latency: #{rf_avg_latency.round(3)} ms"
puts "LLM           — Avg latency: #{llm_avg_latency.round(1)} ms"
puts "LLM is ~#{(llm_avg_latency / rf_avg_latency).round(0)}x slower"
puts

# ============================================================================
# EXPERIMENT 3 — Consistency Test
# ============================================================================

puts "=" * 70
puts "EXPERIMENT 3: Consistency (Variance) Test"
puts "=" * 70

# Pick 3 test cases
consistency_cases = test_features[0..2]
consistency_actual = test_prices[0..2]

consistency_cases.each_with_index do |features, ci|
  bedrooms, full_bath, half_bath, sqft, lot_sqft = features
  total_bath = full_bath + (half_bath * 0.5)
  puts "\nCase #{ci + 1}: #{bedrooms.to_i}bed, #{total_bath.round(1)}bath, #{sqft.to_i}sqft, #{lot_sqft.to_i}sqft lot (Actual: #{consistency_actual[ci].round(1)}K)"

  # RF is deterministic
  rf_input = Numo::DFloat[*features].expand_dims(0)
  rf_preds = CONSISTENCY_N.times.map { model.predict(rf_input)[0] }
  puts "  RF predictions:  #{rf_preds.map { |p| p.round(1) }.uniq.join(', ')} (variance: #{rf_preds.uniq.size == 1 ? '0 — deterministic' : 'varies'})"

  # LLM varies
  llm_preds = []
  CONSISTENCY_N.times do |j|
    prompt = <<~PROMPT
      You are a Las Vegas house price estimator. Based on these features, predict the house price in thousands of dollars (K).
      Reply with ONLY a number followed by K. Example: 450K

      Property Features:
      - Bedrooms: #{bedrooms.to_i}
      - Bathrooms: #{total_bath.round(1)} (#{full_bath.to_i} full, #{half_bath.to_i} half)
      - Square Footage: #{sqft.to_i} sqft
      - Lot Size: #{lot_sqft.to_i} sqft

      Predicted price:
    PROMPT

    result = call_llm(prompt, max_tokens: 50, temperature: 1.0)
    price  = extract_number(result[:text])
    llm_preds << price
    print "."
    sleep(0.5)
  end

  llm_variance = llm_preds.sum { |p| (p - llm_preds.sum / llm_preds.size.to_f)**2 } / llm_preds.size.to_f
  puts "\n  LLM predictions: #{llm_preds.map { |p| p.round(1) }.join(', ')}"
  puts "  LLM variance: #{llm_variance.round(2)} | Std dev: #{Math.sqrt(llm_variance).round(2)}K"
end

puts

# ============================================================================
# EXPERIMENT 4 — Hybrid Pipeline (LLM extraction + RF prediction)
# ============================================================================

puts "=" * 70
puts "EXPERIMENT 4: Hybrid Pipeline (NL → LLM extraction → RF prediction)"
puts "=" * 70

natural_language_inputs = [
  { text: "Spacious single family home with 4 bedrooms, 3 full baths and 1 half bath, about 2500 square feet on a 7000 sqft lot", expected: [4, 3, 1, 2500, 7000] },
  { text: "Cozy 3 bed 2 bath house, 1800 sqft, sits on 5500 square foot lot", expected: [3, 2, 0, 1800, 5500] },
  { text: "Luxury property, 5 bedrooms, 4.5 baths (4 full, 1 half), massive 4200 sqft floor plan, 10000 sqft lot", expected: [5, 4, 1, 4200, 10000] },
  { text: "Small starter home, 2 bedrooms, 2 bathrooms, compact 1200 square feet on a 3000 sqft lot", expected: [2, 2, 0, 1200, 3000] },
  { text: "Modern home with three bedrooms, two and a half baths, 2000 square feet of living space, 6500 sqft lot", expected: [3, 2, 1, 2000, 6500] },
]

extraction_results = []

natural_language_inputs.each_with_index do |input, i|
  prompt = <<~PROMPT
    Extract house features from the following description. Return ONLY a JSON object with these exact keys:
    {"bedrooms": <number>, "full_bathrooms": <number>, "half_bathrooms": <number>, "size_sqft": <number>, "lot_size": <number>}

    Description: "#{input[:text]}"

    JSON:
  PROMPT

  result = call_llm(prompt, max_tokens: 100, temperature: 0.0)

  begin
    # Try to extract JSON from response
    json_match = result[:text].match(/\{[^}]+\}/)
    parsed = JSON.parse(json_match[0])
    extracted = [parsed['bedrooms'], parsed['full_bathrooms'], parsed['half_bathrooms'], parsed['size_sqft'], parsed['lot_size']]
  rescue StandardError => e
    puts "  [#{i + 1}] Extraction failed: #{e.message}"
    puts "  Raw response: #{result[:text]}"
    extracted = [0, 0, 0, 0, 0]
  end

  expected = input[:expected]
  correct = extracted == expected

  # Run RF prediction with extracted features
  rf_input = Numo::DFloat[*extracted.map(&:to_f)].expand_dims(0)
  rf_pred  = model.predict(rf_input)[0]

  # Also run RF with correct features for comparison
  rf_correct_input = Numo::DFloat[*expected.map(&:to_f)].expand_dims(0)
  rf_correct_pred  = model.predict(rf_correct_input)[0]

  extraction_results << {
    text: input[:text],
    expected: expected,
    extracted: extracted,
    correct: correct,
    rf_pred_extracted: rf_pred.round(1),
    rf_pred_correct: rf_correct_pred.round(1)
  }

  puts "  [#{i + 1}] Expected: #{expected} | Extracted: #{extracted} | Match: #{correct ? '✅' : '❌'}"
  puts "       RF price (from extracted): #{rf_pred.round(1)}K | RF price (from correct): #{rf_correct_pred.round(1)}K"
  sleep(0.5)
end

accuracy = extraction_results.count { |r| r[:correct] }.to_f / extraction_results.size * 100
puts "\nExtraction accuracy: #{accuracy.round(1)}%"
puts

# ============================================================================
# Summary — Save to Markdown
# ============================================================================

puts "=" * 70
puts "Saving results to benchmark_results.md"
puts "=" * 70

markdown = <<~MD
  # Benchmark Results: Random Forest vs LLM for House Price Prediction

  **Date:** #{Time.now.strftime('%Y-%m-%d %H:%M')}
  **LLM Model:** #{MODEL}
  **RF Estimators:** 100
  **Dataset:** Las Vegas Housing (#{data.size} valid rows from #{csv_data.size} total)
  **Train/Test Split:** #{train_data.size} / #{test_data.size}
  **Features:** Bedrooms, Full Bathrooms, Half Bathrooms, Square Footage, Lot Size
  **Test subset for LLM:** #{test_subset_size} cases

  ## Experiment 1 — Accuracy (on #{test_subset_size} test cases)

  | Metric | Random Forest | LLM (#{MODEL}) |
  |--------|--------------|----------------|
  | MAE    | #{rf_mae_subset.round(2)}K | #{llm_mae.round(2)}K |
  | RMSE   | #{rf_rmse_subset.round(2)}K | #{llm_rmse.round(2)}K |

  ## Experiment 2 — Latency

  | Metric | Random Forest | LLM |
  |--------|--------------|-----|
  | Avg latency | #{rf_avg_latency.round(3)} ms | #{llm_avg_latency.round(1)} ms |
  | Speedup | — | ~#{(llm_avg_latency / rf_avg_latency).round(0)}x slower |

  ## Experiment 3 — Consistency (#{CONSISTENCY_N} repeated predictions per case)

  | Case | RF Variance | LLM Std Dev |
  |------|-------------|-------------|
  #{consistency_cases.each_with_index.map do |features, ci|
    "| #{features.map(&:to_i).join(', ')} | 0 (deterministic) | — (see raw output) |"
  end.join("\n")}

  _(Fill in LLM std dev values from the raw output above)_

  ## Experiment 4 — Hybrid Pipeline (NL → LLM → RF)

  | Input | Expected | Extracted | Match | RF Price (extracted) | RF Price (correct) |
  |-------|----------|-----------|-------|---------------------|--------------------|
  #{extraction_results.map do |r|
    "| #{r[:text][0..40]}... | #{r[:expected]} | #{r[:extracted]} | #{r[:correct] ? '✅' : '❌'} | #{r[:rf_pred_extracted]}K | #{r[:rf_pred_correct]}K |"
  end.join("\n")}

  **Extraction accuracy:** #{accuracy.round(1)}%
MD

File.write('benchmark_results.md', markdown)
puts "Done! Results saved to benchmark_results.md"
