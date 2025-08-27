# frozen_string_literal: true

# Example usage of Gemini::Skills class
# This file demonstrates how to use the skills validation functionality

require_relative '../skills'

# Example 1: Basic usage
def basic_skills_validation_example
  skills_to_validate = [
    "React.Js",
    "Project Manager", 
    "Communication",
    "Increase Revenue",
    "Advanced Excel",
    "Sales/Marketing",
    "ISO 27001:2022",
    "GDPR",
    "AI",
    "Sales and Operations Planning",
    "Salesforce",
    "Hindi",
    "PMP"
  ]

  # Initialize the skills validator with a user ID
  skills_validator = Gemini::Skills.new(user_id: 61434)
  
  # Validate the skills
  chat_result = skills_validator.validate_skills(skills_to_validate)
  
  puts "Skills validation completed!"
  puts "Chat ID: #{chat_result.id}" if chat_result.respond_to?(:id)
  
  chat_result
rescue => e
  puts "Error during skills validation: #{e.message}"
  nil
end

# Example 2: Custom configuration
def custom_config_example
  skills_to_validate = ["Python", "Machine Learning", "Data Analysis"]
  
  # Custom configuration for different model or settings
  custom_config = {
    model: 'gemini-2.5-pro',
    thinking_mode: true,
    prompt_type: 'advanced_skill_validation'
  }
  
  skills_validator = Gemini::Skills.new(
    user_id: 12345,
    config: custom_config
  )
  
  chat_result = skills_validator.validate_skills(skills_to_validate)
  puts "Custom configuration validation completed!"
  
  chat_result
rescue => e
  puts "Error with custom configuration: #{e.message}"
  nil
end

# Example 3: Overriding user ID at validation time
def override_user_id_example
  skills_to_validate = ["Ruby on Rails", "PostgreSQL", "Docker"]
  
  # Initialize without user ID
  skills_validator = Gemini::Skills.new
  
  # Provide user ID during validation
  chat_result = skills_validator.validate_skills(
    skills_to_validate, 
    user_id: 98765
  )
  
  puts "User ID override validation completed!"
  
  chat_result
rescue => e
  puts "Error with user ID override: #{e.message}"
  nil
end

# Example 4: Using utility methods for direct results
def utility_methods_example
  skills_to_validate = ["Ruby on Rails", "Project Management", "Communication"]
  
  # Direct validation and parsing in one step
  results = Gemini::Skills.validate_and_parse(
    skills_to_validate,
    user_id: 55555
  )
  
  puts "Direct results:"
  results.each do |result|
    puts "  #{result['original_input']} -> #{result['canonical_name']} (valid: #{result['is_valid']})"
  end
  
  results
rescue => e
  puts "Error with utility methods: #{e.message}"
  nil
end

# Example 5: Error handling demonstration
def error_handling_example
  skills_validator = Gemini::Skills.new(user_id: 11111)
  
  # Test various error conditions
  test_cases = [
    { skills: [], description: "Empty array" },
    { skills: "not an array", description: "Non-array input" },
    { skills: [123, "valid skill"], description: "Mixed types" },
    { skills: nil, description: "Nil input" }
  ]
  
  test_cases.each do |test_case|
    begin
      puts "Testing: #{test_case[:description]}"
      skills_validator.validate_skills(test_case[:skills])
      puts "✓ Unexpectedly succeeded"
    rescue ArgumentError => e
      puts "✓ Correctly caught error: #{e.message}"
    rescue => e
      puts "✗ Unexpected error: #{e.message}"
    end
    puts
  end
end

# Run examples if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  puts "=== Gemini Skills Validation Examples ==="
  puts
  
  puts "1. Basic Usage Example:"
  basic_skills_validation_example
  puts
  
  puts "2. Custom Configuration Example:"
  custom_config_example
  puts
  
  puts "3. User ID Override Example:"
  override_user_id_example
  puts
  
  puts "4. Utility Methods Example:"
  utility_methods_example
  puts
  
  puts "5. Error Handling Examples:"
  error_handling_example
end
