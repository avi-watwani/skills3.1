module Gemini
  class Chat < Client
    attr_accessor :user_id, :messages, :model, :max_tokens, :temperature, :thinking_mode, :response

    # Configuration for supported models.
    # Defines behavior when thinking_mode is disabled.
    MODEL_CONFIG = {
      'gemini-2.5-pro' => {},
      'gemini-2.5-flash' => {
        # When thinking_mode is false, use this temperature for the flash model.
        temp_when_thinking_disabled: 0
      }
    }.freeze

    SUPPORTED_MODELS = MODEL_CONFIG.keys.freeze
    DEFAULT_MODEL = 'gemini-2.5-flash'.freeze

    def initialize(user_id: nil, messages: [], model: DEFAULT_MODEL, max_tokens: 2048, temperature: 0.1, log_request: true, prompt_type: nil, thinking_mode: false)
      self.user_id = user_id
      self.messages = messages
      self.model = model
      self.max_tokens = max_tokens
      self.temperature = temperature
      self.thinking_mode = thinking_mode
      super(prompt_type: prompt_type)
    end

    def create
      # Always use the non-streaming endpoint as requested.
      endpoint = "/models/#{model}:generateContent"
      @response = post(endpoint, params_for_create)
      @response
    end

    private

    def params_for_create
      generation_config = {
        maxOutputTokens: max_tokens,
        temperature: temperature
      }

      # If thinking_mode is disabled, check if a temperature override is configured.
      unless thinking_mode
        temp_override = MODEL_CONFIG.dig(model, :temp_when_thinking_disabled)
        generation_config[:temperature] = temp_override unless temp_override.nil?
        generation_config[:thinkingConfig] = { thinkingBudget: 0 }
      end

      {
        contents: formatted_messages,
        generationConfig: generation_config
      }
    end

    def formatted_messages
      # Gemini API expects a specific structure for messages.
      # It alternates between 'user' and 'model' roles.
      messages.map do |message|
        {
          role: message[:role] == 'assistant' ? 'model' : message[:role],
          parts: [{ text: message[:content] }]
        }
      end
    end
  end
end
