#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Simple test
batch = ["React.Js", "Project Manager"]
chat = Gemini::Skills.new.validate_skills(batch)
results = Gemini::Skills.parse_results(chat)

if results.present? && results.is_a?(Array)
  puts "✓ Success! Got #{results.length} results:"
  puts JSON.pretty_generate(results)
else
  puts "⚠ Parsing failed, trying manual extraction..."
  
  # Debug the response
  if chat.response && chat.response.data
    response_text = chat.response.data.dig('candidates', 0, 'content', 'parts', 0, 'text')
    puts "Raw response text:"
    puts response_text.inspect
    
    if response_text
      # Try parsing manually
      json_text = response_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
      puts "\nCleaned JSON text:"
      puts json_text.inspect
      
      begin
        manual_results = JSON.parse(json_text)
        puts "\n✓ Manual parsing successful:"
        puts JSON.pretty_generate(manual_results)
      rescue JSON::ParserError => e
        puts "\n✗ Manual parsing failed: #{e.message}"
      end
    end
  end
end
