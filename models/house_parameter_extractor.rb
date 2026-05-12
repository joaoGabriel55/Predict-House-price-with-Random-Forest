require 'ruby_llm'
require 'dotenv/load'

class HouseParameterExtractor
  def initialize
    @context = RubyLLM.context do |config|
      config.openrouter_api_key = ENV['OPENROUTER_API_KEY']
      config.default_model = 'anthropic/claude-opus-4.6'
    end
  end

  def extract_parameters(text)
    prompt = <<~PROMPT
      Extract the house parameters from the following text. Return ONLY a JSON object with these exact keys:
      - area: the area in square feet (numeric value, or null if not mentioned)
      - rooms: the number of rooms (numeric value, or null if not mentioned)
      - bathrooms: the number of bathrooms (numeric value, or null if not mentioned)
      - age: the age of the house in years (numeric value, or null if not mentioned)

      Text: #{text}

      Respond with ONLY the JSON object, no other text.
    PROMPT

    puts @context

    chat = @context.chat(provider: 'openrouter')
    response = chat.ask(prompt)
    content = response.content.strip

    json_match = content.match(/\{[^}]+\}/)
    raise "Could not extract JSON from LLM response" unless json_match

    params = JSON.parse(json_match[0])

    missing = []
    missing << 'area' if params['area'].nil?
    missing << 'rooms' if params['rooms'].nil?
    missing << 'bathrooms' if params['bathrooms'].nil?
    missing << 'age' if params['age'].nil?

    if missing.any?
      raise "Missing parameters: #{missing.join(', ')}. Please provide all house details."
    end

    {
      area: params['area'].to_f,
      rooms: params['rooms'].to_f,
      bathrooms: params['bathrooms'].to_f,
      age: params['age'].to_f
    }
  rescue JSON::ParserError => e
    raise "Failed to parse LLM response: #{e.message}"
  rescue => e
    puts e
    raise "Failed to extract parameters: #{e.message}"
  end
end
