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
    construction_year = params[:construction_year] || params["construction_year"]
    lot_sqft          = params[:lot_sqft] || params["lot_sqft"]
    calc_acres        = params[:calc_acres] || params["calc_acres"]
    land_value        = params[:land_value] || params["land_value"]
    improvement_value = params[:improvement_value] || params["improvement_value"]
    zipcode           = params[:zipcode] || params["zipcode"]

    price = @predictor.predict(
      construction_year: construction_year.to_f,
      lot_sqft: lot_sqft.to_f,
      calc_acres: calc_acres.to_f,
      land_value: land_value.to_f,
      improvement_value: improvement_value.to_f,
      zipcode: zipcode.to_f
    )

    {
      view: :result,
      locals: {
        construction_year: construction_year,
        lot_sqft: lot_sqft,
        calc_acres: calc_acres,
        land_value: land_value,
        improvement_value: improvement_value,
        zipcode: zipcode,
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
      Extract the Las Vegas house parameters from the following description and use the tool to predict the price:
      #{text}

      Extract: construction_year (year built), lot_sqft (lot size in square feet), calc_acres (calculated acres),
      land_value (land value in dollars), improvement_value (building/improvement value in dollars), and zipcode.
    PROMPT

    chat.ask(prompt)

    raise "Tool was not called or returned no result" if tool_result.nil?

    if tool_result[:error]
      raise tool_result[:error]
    end

    {
      view: :llm_result,
      locals: {
        construction_year: tool_result[:construction_year],
        lot_sqft: tool_result[:lot_sqft],
        calc_acres: tool_result[:calc_acres] <= 0.0 ? 0 : tool_result[:calc_acres],
        land_value: tool_result[:land_value],
        improvement_value: tool_result[:improvement_value],
        zipcode: tool_result[:zipcode],
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
