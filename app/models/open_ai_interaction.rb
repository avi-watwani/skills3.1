class OpenAIInteraction < ApplicationRecord
  # Serialize JSON fields for easier handling
  serialize :request_body, JSON
  serialize :response_body, JSON
  
  # Validations
  validates :http_status_code, presence: true
  validates :request_body, presence: true
  validates :response_body, presence: true
  
  # Scopes for common queries
  scope :successful, -> { where(http_status_code: 200..299) }
  scope :failed, -> { where.not(http_status_code: 200..299) }
  scope :recent, -> { order(created_at: :desc) }
  scope :skills_validations, -> { where('request_body IS NOT NULL').where("request_body NOT LIKE '%contents%'") }
  
  # Helper method to check if the request was successful
  def successful?
    http_status_code.between?(200, 299)
  end
  
  # Helper method to extract skills validation results from response
  def skills_validation_results
    return [] unless successful? && response_body.present?
    
    # Parse the response if it's a string
    parsed_response = response_body.is_a?(String) ? JSON.parse(response_body) : response_body
    
    # Try to extract the text content and parse it
    if parsed_response.is_a?(Hash)
      # Handle Gemini API response structure
      text_content = parsed_response.dig('candidates', 0, 'content', 'parts', 0, 'text') ||
                    parsed_response.dig('data', 'candidates', 0, 'content', 'parts', 0, 'text')
      
      if text_content.present?
        # Clean up JSON formatting
        json_text = text_content.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
        return JSON.parse(json_text) if json_text.start_with?('[', '{')
      end
    end
    
    []
  rescue JSON::ParserError
    []
  end
end
