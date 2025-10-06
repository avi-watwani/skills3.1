require 'httparty'

module Gemini
  class Client
    include HTTParty
    base_uri 'https://generativelanguage.googleapis.com/v1beta'

    attr_accessor :user_id, :model

    def initialize(prompt_type: nil)
      raise ArgumentError, 'Gemini API key is not set' if Gemini.api_key.nil? || Gemini.api_key.strip.empty?

      @prompt_type = prompt_type
      @headers = {
        'Content-Type' => 'application/json',
        'x-goog-api-key' => Gemini.api_key
      }
    end

    def post(endpoint, body)
      response_obj = nil
      begin
        response = self.class.post(endpoint, body: body.to_json, headers: @headers, timeout: 120)
        response_obj = if response.success?
                         Gemini::ResponseObject.new(data: response.parsed_response, status: response.code)
                       else
                         handle_error(response)
                       end
      rescue Net::ReadTimeout, Net::OpenTimeout, HTTParty::Error, StandardError => e
        response_obj = handle_error(e)
      end

      response_obj
    end

    private

    def handle_error(response_or_exception)
      error_message = 'An unknown error occurred'
      status_code = 500
      response_body_for_notification = ''

      if response_or_exception.is_a?(HTTParty::Response)
        response = response_or_exception
        status_code = response.code
        response_body_for_notification = response.body
        begin
          parsed_body = response.parsed_response
          error_message = if parsed_body.is_a?(Hash)
                            parsed_body.dig('error', 'message') || parsed_body.to_s
                          else
                            parsed_body.to_s
                          end
        rescue JSON::ParserError
          error_message = response.body.to_s
        end
        error_message ||= response.message
        notify_error('Non-successful response from Gemini', endpoint: response.request.path.to_s, status: status_code,
                                                            response_body: response_body_for_notification)
      elsif response_or_exception.is_a?(Exception)
        e = response_or_exception
        error_message = e.message
        notify_error("Gemini API Error: #{e.class}", exception: e)
      end

      Gemini::ResponseObject.new(error_message: error_message, status: status_code)
    end

    # Instead of notifying via ExceptionNotifier, add error details to a hash for easier handling.
    def notify_error(message, details = {})
      { error: { message: message, details: details } }
    end

    def extract_token_usage(response)
      return nil unless response.data

      # For streaming responses, find the usageMetadata in the last chunk.
      if response.data.is_a?(Array)
        response.data.last&.dig('usageMetadata', 'totalTokenCount')
      else
        # For non-streaming responses.
        response.data.dig('usageMetadata', 'totalTokenCount')
      end
    end

    def extract_cost(_response)
      # TODO: Implement cost calculation for Gemini based on token usage
      0.0
    end
  end
end
