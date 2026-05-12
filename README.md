# 🏠 House Price Predictor with Random Forest

A machine-learning-powered web application that predicts house prices based on property features. Built with **Ruby**, **Sinatra**, and **Rumale** (a Ruby machine learning library), this project trains a **Random Forest Regressor** on synthetic housing data and serves predictions through a clean web interface.

**NEW:** Now features an **AI Text Mode** that combines LLM natural language understanding with Random Forest predictions, plus comprehensive benchmarks comparing traditional ML vs LLM approaches.

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=flat&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=flat&logo=ruby-sinatra&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Claude](https://img.shields.io/badge/Claude-000000?style=flat&logo=anthropic&logoColor=white)

---

## ✨ Features

- **Random Forest Regression** — Uses Rumale's `RandomForestRegressor` with 100 estimators for accurate predictions
- **AI Text Mode** — Describe houses in natural language! LLM uses RF prediction as a tool for intelligent responses
- **Dual Interface** — Traditional form-based input (`/`) and natural language input (`/llm`)
- **Tool-Based Architecture** — LLM uses Random Forest as a callable tool, combining natural language understanding with ML precision
- **Comprehensive Benchmarks** — Rigorous comparison of RF vs LLM across accuracy, latency, consistency, and hybrid pipelines
- **Singleton Model** — The trained model is loaded once and reused across requests for performance
- **Synthetic Data Generator** — A Python script to generate realistic training samples at scale
- **Simple MVC Architecture** — Clean separation into models, views, and controllers

---

## 🛠 Tech Stack

| Component         | Technology                          |
| ------------------ | ----------------------------------- |
| **Web Framework**  | [Sinatra](http://sinatrarb.com/) 4  |
| **ML Library**     | [Rumale](https://github.com/yoshoku/rumale) 2.1 |
| **LLM Integration**| [ruby_llm](https://github.com/crmne/ruby_llm) + [OpenRouter API](https://openrouter.ai/) |
| **LLM Model**      | Claude Opus 4.6 (via OpenRouter)    |
| **Web Server**     | [Puma](https://puma.io/) 6          |
| **Language**       | Ruby                                |
| **Data Generation**| Python 3                            |

---

## 📂 Project Structure

```
.
├── controllers/
│   └── predictions_controller.rb   # Handles prediction requests (form + LLM modes)
├── models/
│   ├── house_predictor.rb          # Singleton wrapper around the trained model
│   └── house_predictor_llm.rb      # RubyLLM Tool for LLM-powered predictions
├── views/
│   ├── index.erb                   # Traditional input form page
│   ├── result.erb                  # Traditional prediction result page
│   ├── llm_index.erb               # AI text mode input page
│   └── llm_result.erb              # AI text mode result page with extraction details
├── public/
│   └── style.css                   # Application styles
├── generate_samples.py             # Python script to generate training data
├── save_model.rb                   # Script to train and persist the model
├── test_model.rb                   # Quick script to test predictions from CLI
├── benchmark.rb                    # Comprehensive RF vs LLM benchmark suite
├── benchmark_results.md            # Latest benchmark results
├── server.rb                       # Sinatra application entry point
├── houses.csv                      # Training dataset
├── house_model.dat                 # Serialized trained model
├── .env                            # Environment variables (OPENROUTER_API_KEY)
├── Gemfile                         # Ruby dependencies
└── Gemfile.lock                    # Locked dependency versions
```

---

## 📋 Prerequisites

- **Ruby** (3.0 or higher recommended)
- **Bundler** (`gem install bundler`)
- **Python 3** (only required if you want to regenerate training data)
- **OpenRouter API Key** (required for AI text mode and benchmarks) — Get one at [openrouter.ai](https://openrouter.ai/)

---

## 🚀 Setup & Installation

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/predicting-houses-prices-with-random-florest.git
cd predicting-houses-prices-with-random-florest
```

### 2. Install Ruby dependencies

```bash
bundle install
```

### 3. Configure API access (required for AI Text Mode)

Create a `.env` file in the project root:

```bash
echo "OPENROUTER_API_KEY=your_api_key_here" > .env
```

Replace `your_api_key_here` with your actual OpenRouter API key. This is required for:
- AI Text Mode (`/llm` route)
- Running benchmarks (`benchmark.rb`)

> **Note:** The traditional form-based prediction works without an API key.

### 4. (Optional) Generate more training data

The repository already ships with a `houses.csv` dataset. If you want to regenerate or expand it:

```bash
python3 generate_samples.py
```

This appends **10,000** synthetic samples to `houses.csv` with realistic price estimations based on area, rooms, bathrooms, and age.

### 5. Train the model

Train the Random Forest model and save it to `house_model.dat`:

```bash
ruby save_model.rb
```

> **Note:** A pre-trained `house_model.dat` is already included in the repository. You only need to re-run this step if you modify the training data or model parameters.

---

## ▶️ Running the Application

Start the Sinatra web server:

```bash
ruby server.rb
```

The application will start on **http://localhost:4567**. Open this URL in your browser.

### Using the App

**Traditional Mode** (`http://localhost:4567/`)

1. Fill in the property features on the form:
   - **Area** — Size of the house in square feet
   - **Rooms** — Number of rooms
   - **Bathrooms** — Number of bathrooms
   - **Age** — Age of the house in years
2. Click **Predict Price**
3. View the predicted price (in thousands of dollars)

**AI Text Mode** (`http://localhost:4567/llm`)

1. Describe your house in natural language. Examples:
   - "A spacious 250 square meter house with 5 bedrooms and 3 bathrooms, built about 10 years ago"
   - "Small apartment, 60m², 2 rooms, 1 bathroom, pretty new, around 2 years old"
   - "Old colonial mansion with 400 square meters, 8 rooms, 4 baths, over 50 years old"
2. Click **Predict with AI**
3. View the extracted parameters and predicted price
4. The result page shows:
   - How the LLM interpreted your description
   - Extracted structured features
   - Final price prediction from the Random Forest model

---

## 🧪 Testing the Model from the CLI

You can quickly test the model without starting the server:

```bash
ruby test_model.rb
```

This loads the serialized model and predicts the price for a sample house (500 sq ft, 10 rooms, 5 bathrooms, 20 years old).

---

## 📊 Running Benchmarks

Compare Random Forest vs LLM performance across multiple dimensions:

```bash
ruby benchmark.rb
```

This runs 4 comprehensive experiments:

1. **Accuracy Comparison** — MAE and RMSE metrics on 20 test cases
2. **Latency Comparison** — Average prediction time for RF vs LLM
3. **Consistency Test** — Variance analysis (RF is deterministic, LLM varies)
4. **Hybrid Pipeline** — Natural language extraction accuracy + RF prediction

Results are printed to stdout and saved to `benchmark_results.md`.

**Latest Results Snapshot:**
- **RF MAE:** 8.21K | **LLM MAE:** 155.4K (RF is ~19x more accurate)
- **RF Latency:** 0.45ms | **LLM Latency:** 4,040ms (LLM is ~9,000x slower)
- **Hybrid Extraction Accuracy:** 100% (5/5 test cases correctly parsed)

> **Key Insight:** The hybrid approach (LLM for understanding + RF for prediction) combines the best of both worlds—natural language interface with ML precision.

---

## 🧠 How It Works

### Training Pipeline

1. **Data Loading** — `save_model.rb` reads `houses.csv`, which contains rows of `[area, rooms, bathrooms, age, price]`
2. **Model Training** — A `Rumale::Ensemble::RandomForestRegressor` is trained with:
   - `n_estimators: 100` (100 decision trees)
   - `max_depth: nil` (trees grow until pure leaves)
   - `random_seed: 42` (reproducible results)
3. **Serialization** — The trained model is serialized with `Marshal.dump` to `house_model.dat`

### Prediction Pipeline (Traditional)

1. The `HousePredictor` singleton loads the model once at application startup
2. When a user submits the form, `PredictionsController` extracts the parameters
3. The input features are converted to a `Numo::DFloat` array and passed to `model.predict`
4. The predicted price (in thousands) is displayed on the result page

### Tool-Based Pipeline (AI Text Mode)

1. **Natural Language Input** — User describes the house in plain English
2. **LLM Tool Call** — `HousePredictorLLM` is registered as a callable tool with Claude Opus 4.6 via OpenRouter
3. **Parameter Extraction** — LLM parses the description and calls the tool with `{area, rooms, bathrooms, age}`
4. **RF Execution** — The tool executes `HousePredictor.predict()` with the extracted parameters
5. **Structured Response** — Tool returns the prediction result back to the LLM
6. **Result Display** — Shows the extracted features and the final price prediction

This architecture leverages:
- **LLM strengths:** Understanding context, handling varied phrasing, autonomous tool use
- **RF strengths:** Fast, accurate, deterministic predictions based on structured data
- **Tool Pattern:** LLM decides when and how to call the RF model, enabling more intelligent interactions

### Data Generation

The `generate_samples.py` script uses a simple linear formula with noise to create realistic training data:

```
price ≈ 2.2 × area + 20 × rooms + 15 × bathrooms − 3 × age ± 5% noise
```

---

## 📊 Dataset Format

The `houses.csv` file has no header row. Each row contains five comma-separated integer values:

| Column | Description                    | Example |
| ------ | ------------------------------ | ------- |
| 1      | Area (sq ft)                   | 200     |
| 2      | Number of rooms                | 4       |
| 3      | Number of bathrooms            | 3       |
| 4      | Age of the house (years)       | 5       |
| 5      | Price (in thousands of dollars)| 550     |

---

## 🔬 Key Findings: RF vs LLM

Based on comprehensive benchmarks (`benchmark_results.md`):

| Aspect | Random Forest | LLM (Claude Opus 4.6) | Winner |
|--------|--------------|----------------------|--------|
| **Accuracy (MAE)** | 8.21K | 155.4K | 🏆 **RF** (19x better) |
| **Speed** | 0.45ms | 4,040ms | 🏆 **RF** (9,000x faster) |
| **Consistency** | Deterministic (0 variance) | High variance across runs | 🏆 **RF** |
| **Natural Language** | ❌ Requires structured input | ✅ Understands descriptions | 🏆 **LLM** |
| **Cost** | Free (local computation) | ~$0.05 per prediction | 🏆 **RF** |

### Recommended Approach

For **production house price prediction**, use **Random Forest**. It's more accurate, faster, and cost-effective.

For **user-facing interfaces**, consider the **tool-based approach** (LLM + RF tool):
- Allows natural language input (better UX)
- Maintains RF's accuracy for the actual prediction
- LLM intelligently calls the RF tool when needed
- Enables more sophisticated interactions beyond simple parameter extraction

### When to Use LLMs

LLMs make sense when:
- You need to process unstructured text (listings, descriptions, user queries)
- The input format varies widely
- User experience demands conversational interfaces
- You're building a chatbot or voice assistant

For direct numeric predictions with structured data, traditional ML wins on accuracy, speed, and cost.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
