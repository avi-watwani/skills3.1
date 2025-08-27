#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Test batch of skills
batch = [
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

puts "Testing Gemini Skills validation with #{batch.length} skills..."
puts "Skills: #{batch.join(', ')}"
puts "\n" + "="*50 + "\n"

begin
  # Create the skills validator and validate
  chat = Gemini::Skills.new.validate_skills(batch)
  puts "✓ Skills validation request completed successfully!"
  
  # Try to get the results
  results = Gemini::Skills.parse_results(chat)
  
  if results.present? && results.is_a?(Array)
    puts "✓ Got #{results.length} results back from Gemini"
    puts "\n" + "="*50 + "\n"
    puts "JSON OUTPUT:"
    puts JSON.pretty_generate(results)
  else
    puts "⚠ Could not parse results, trying manual extraction..."
    
    # Try to extract manually from response
    if chat.response && chat.response.data
      response_text = chat.response.data.dig('candidates', 0, 'content', 'parts', 0, 'text')
      if response_text
        puts "Raw response text found:"
        puts response_text
        
        # Try to parse JSON from response
        json_text = response_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
        
        begin
          parsed_results = JSON.parse(json_text)
          puts "\n" + "="*50 + "\n"
          puts "PARSED JSON OUTPUT:"
          puts JSON.pretty_generate(parsed_results)
        rescue JSON::ParserError => e
          puts "Error parsing JSON: #{e.message}"
          puts "JSON text was: #{json_text}"
        end
      else
        puts "No text content found in response"
        puts "Response structure: #{chat.response.data.inspect}"
      end
    else
      puts "No response data available"
    end
  end
  
rescue => e
  puts "✗ Error during validation: #{e.message}"
  puts "Error class: #{e.class}"
  puts "Backtrace:"
  puts e.backtrace.first(10).join("\n")
end
