# frozen_string_literal: true

module Gemini
  module Helpers
    class ResponseParser
      # Parse the raw response text and extract the JSON content
      def self.parse_skills_validation(response_text)
        # Remove code block formatting if present
        json_text = response_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
        
        # Parse the JSON
        JSON.parse(json_text)
      rescue JSON::ParserError => e
        Rails.logger.error "Failed to parse skills validation response: #{e.message}"
        Rails.logger.error "Raw response: #{response_text}"
        []
      end

      # Extract the response text from the full response structure
      def self.extract_response_text(full_response)
        return nil unless full_response.is_a?(Hash)
        
        # Try different response structures
        candidates = full_response.dig('data', 'candidates') || 
                    full_response['candidates'] ||
                    [full_response]
        
        candidates&.first&.dig('content', 'parts')&.first&.dig('text')
      end

      # Complete parsing pipeline
      def self.parse_interaction(interaction)
        response_text = extract_response_text(interaction.response_body)
        return [] unless response_text
        
        parse_skills_validation(response_text)
      end
    end
  end
end
