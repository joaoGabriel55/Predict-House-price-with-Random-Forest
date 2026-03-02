# 🏠 House Price Predictor with Random Forest

A machine-learning-powered web application that predicts house prices based on property features. Built with **Ruby**, **Sinatra**, and **Rumale** (a Ruby machine learning library), this project trains a **Random Forest Regressor** on synthetic housing data and serves predictions through a clean web interface.

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=flat&logo=ruby&logoColor=white)
![Sinatra](https://img.shields.io/badge/Sinatra-000000?style=flat&logo=ruby-sinatra&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

---

## ✨ Features

- **Random Forest Regression** — Uses Rumale's `RandomForestRegressor` with 100 estimators for accurate predictions
- **Web Interface** — A polished, responsive UI built with Sinatra and ERB templates
- **Singleton Model** — The trained model is loaded once and reused across requests for performance
- **Synthetic Data Generator** — A Python script to generate realistic training samples at scale
- **Simple MVC Architecture** — Clean separation into models, views, and controllers

---

## 🛠 Tech Stack

| Component         | Technology                          |
| ------------------ | ----------------------------------- |
| **Web Framework**  | [Sinatra](http://sinatrarb.com/) 4  |
| **ML Library**     | [Rumale](https://github.com/yoshoku/rumale) 2.1 |
| **Web Server**     | [Puma](https://puma.io/) 6          |
| **Language**       | Ruby                                |
| **Data Generation**| Python 3                            |

---

## 📂 Project Structure

```
.
├── controllers/
│   └── predictions_controller.rb   # Handles prediction requests
├── models/
│   └── house_predictor.rb          # Singleton wrapper around the trained model
├── views/
│   ├── index.erb                   # Input form page
│   └── result.erb                  # Prediction result page
├── public/
│   └── style.css                   # Application styles
├── generate_samples.py             # Python script to generate training data
├── save_model.rb                   # Script to train and persist the model
├── test_model.rb                   # Quick script to test predictions from CLI
├── server.rb                       # Sinatra application entry point
├── houses.csv                      # Training dataset
├── house_model.dat                 # Serialized trained model
├── Gemfile                         # Ruby dependencies
└── Gemfile.lock                    # Locked dependency versions
```

---

## 📋 Prerequisites

- **Ruby** (3.0 or higher recommended)
- **Bundler** (`gem install bundler`)
- **Python 3** (only required if you want to regenerate training data)

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

### 3. (Optional) Generate more training data

The repository already ships with a `houses.csv` dataset. If you want to regenerate or expand it:

```bash
python3 generate_samples.py
```

This appends **10,000** synthetic samples to `houses.csv` with realistic price estimations based on area, rooms, bathrooms, and age.

### 4. Train the model

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

1. Fill in the property features on the form:
   - **Area** — Size of the house in square feet
   - **Rooms** — Number of rooms
   - **Bathrooms** — Number of bathrooms
   - **Age** — Age of the house in years
2. Click **Predict Price**
3. View the predicted price (in thousands of dollars)

---

## 🧪 Testing the Model from the CLI

You can quickly test the model without starting the server:

```bash
ruby test_model.rb
```

This loads the serialized model and predicts the price for a sample house (500 sq ft, 10 rooms, 5 bathrooms, 20 years old).

---

## 🧠 How It Works

### Training Pipeline

1. **Data Loading** — `save_model.rb` reads `houses.csv`, which contains rows of `[area, rooms, bathrooms, age, price]`
2. **Model Training** — A `Rumale::Ensemble::RandomForestRegressor` is trained with:
   - `n_estimators: 100` (100 decision trees)
   - `max_depth: nil` (trees grow until pure leaves)
   - `random_seed: 42` (reproducible results)
3. **Serialization** — The trained model is serialized with `Marshal.dump` to `house_model.dat`

### Prediction Pipeline

1. The `HousePredictor` singleton loads the model once at application startup
2. When a user submits the form, `PredictionsController` extracts the parameters
3. The input features are converted to a `Numo::DFloat` array and passed to `model.predict`
4. The predicted price (in thousands) is displayed on the result page

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).