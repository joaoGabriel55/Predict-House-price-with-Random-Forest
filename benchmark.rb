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
CSV_FILE       = 'houses.csv'
TEST_RATIO     = 0.2          # 20% of data for testing
CONSISTENCY_N  = 10           # number of repeated LLM calls per test case
RANDOM_SEED    = 42

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
  puts "TEXT TEXT"
  puts text
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

raw = CSV.read(CSV_FILE).map { |row| row.map(&:to_f) }
raw.shuffle!(random: Random.new(RANDOM_SEED))

split_idx = (raw.size * (1 - TEST_RATIO)).to_i
train_data = raw[0...split_idx]
test_data  = raw[split_idx..]

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
  area, rooms, bathrooms, age = features

  prompt = <<~PROMPT
    You are a house price estimator. Based on these features, predict the house price in thousands (K).
    Reply with ONLY a number followed by K. Example: 450K

    Features:
    - Area: #{area.to_i} m²
    - Rooms: #{rooms.to_i}
    - Bathrooms: #{bathrooms.to_i}
    - Age: #{age.to_i} years

    Predicted price:
  PROMPT

  result = call_llm(prompt, max_tokens: 50)
  price  = extract_number(result[:text])

  llm_predictions << price
  llm_latencies << result[:latency]

  puts "  [#{i + 1}/#{test_subset_size}] Actual: #{test_prices[i]}K | LLM: #{price}K (#{result[:latency].round(2)}s)"
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
  area, rooms, bathrooms, age = features
  puts "\nCase #{ci + 1}: Area=#{area.to_i}m², Rooms=#{rooms.to_i}, Bath=#{bathrooms.to_i}, Age=#{age.to_i} (Actual: #{consistency_actual[ci]}K)"

  # RF is deterministic
  rf_input = Numo::DFloat[*features].expand_dims(0)
  rf_preds = CONSISTENCY_N.times.map { model.predict(rf_input)[0] }
  puts "  RF predictions:  #{rf_preds.map { |p| p.round(1) }.uniq.join(', ')} (variance: #{rf_preds.uniq.size == 1 ? '0 — deterministic' : 'varies'})"

  # LLM varies
  llm_preds = []
  CONSISTENCY_N.times do |j|
    prompt = <<~PROMPT
      You are a house price estimator. Based on these features, predict the house price in thousands (K).
      Reply with ONLY a number followed by K. Example: 450K

      Features:
      - Area: #{area.to_i} m²
      - Rooms: #{rooms.to_i}
      - Bathrooms: #{bathrooms.to_i}
      - Age: #{age.to_i} years

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
  { text: "A spacious 250 square meter house with 5 bedrooms and 3 bathrooms, built about 10 years ago", expected: [250, 5, 3, 10] },
  { text: "Small apartment, 60m², 2 rooms, 1 bathroom, pretty new, around 2 years old", expected: [60, 2, 1, 2] },
  { text: "Old colonial mansion with 400 square meters, 8 rooms, 4 baths, over 50 years old", expected: [400, 8, 4, 50] },
  { text: "Modern 120m² flat, 3 bedrooms, 2 bathrooms, 5 years since construction", expected: [120, 3, 2, 5] },
  { text: "Cozy 80 sqm home, two bedrooms, one bathroom, fifteen years old", expected: [80, 2, 1, 15] },
]

extraction_results = []

natural_language_inputs.each_with_index do |input, i|
  prompt = <<~PROMPT
    Extract house features from the following description. Return ONLY a JSON object with these exact keys:
    {"area": <number>, "rooms": <number>, "bathrooms": <number>, "age": <number>}

    Description: "#{input[:text]}"

    JSON:
  PROMPT

  result = call_llm(prompt, max_tokens: 100, temperature: 0.0)

  begin
    # Try to extract JSON from response
    json_match = result[:text].match(/\{[^}]+\}/)
    parsed = JSON.parse(json_match[0])
    extracted = [parsed['area'], parsed['rooms'], parsed['bathrooms'], parsed['age']]
  rescue StandardError => e
    puts "  [#{i + 1}] Extraction failed: #{e.message}"
    puts "  Raw response: #{result[:text]}"
    extracted = [0, 0, 0, 0]
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
  **Dataset:** #{raw.size} rows (Train: #{train_data.size} / Test: #{test_data.size})
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
