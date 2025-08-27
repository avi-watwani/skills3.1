module Gemini
  class << self
    attr_writer :api_key

    def api_key
      ENV["GEMINI_API_KEY"]
    end

    def configure
      yield self
    end
  end

  ResponseObject = Struct.new(:data, :status, :error_message) do
    def initialize(data: nil, status: nil, error_message: nil)
      super(data, status, error_message)
    end
  end
end
