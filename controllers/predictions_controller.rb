require_relative '../models/house_predictor'
require_relative '../models/house_predictor_llm'
require 'ruby_llm'
require 'dotenv/load'

class PredictionsController
  def initialize
    @predictor = HousePredictor.instance
    @llm_predictor = HousePredictorLLM.new
  end

  def index
    { view: :index, locals: {} }
  end

  def predict(params)
    area      = params[:area] || params["area"]
    rooms     = params[:rooms] || params["rooms"]
    bathrooms = params[:bathrooms] || params["bathrooms"]
    age       = params[:age] || params["age"]

    price = @predictor.predict(
      area: area.to_f,
      rooms: rooms.to_f,
      bathrooms: bathrooms.to_f,
      age: age.to_f
    )

    {
      view: :result,
      locals: {
        area: area,
        rooms: rooms,
        bathrooms: bathrooms,
        age: age,
        price: price
      }
    }
  rescue => e
    {
      view: :index,
      locals: {
        error_message: e.message
      }
    }
  end

  def llm_index
    { view: :llm_index, locals: {} }
  end

  def predict_with_llm(params)
    text = params[:description] || params["description"]

    raise "Please provide a house description" if text.nil? || text.strip.empty?

    context = RubyLLM.context do |config|
      config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
      config.default_model = 'anthropic/claude-opus-4.6'
    end

    # Capture tool result using a callback
    tool_result = nil

    chat = context.chat(provider: 'openrouter')
    chat.after_tool_result do |result|
      tool_result = result
    end

    chat.with_tool(@llm_predictor, choice: :required)

    prompt = <<~PROMPT
      Extract the house parameters from the following description and use the tool to predict the price:
      #{text}

      Extract: area (square feet), rooms (count), bathrooms (count), and age (years).
    PROMPT

    chat.ask(prompt)

    raise "Tool was not called or returned no result" if tool_result.nil?

    if tool_result[:error]
      raise tool_result[:error]
    end

    {
      view: :llm_result,
      locals: {
        area: tool_result[:area],
        rooms: tool_result[:rooms],
        bathrooms: tool_result[:bathrooms],
        age: tool_result[:age],
        price: tool_result[:predicted_price],
        original_text: text
      }
    }
  rescue => e
    {
      view: :llm_index,
      locals: {
        error_message: e.message,
        description: text
      }
    }
  end
end