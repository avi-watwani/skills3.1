#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🗂️  Exporting Skills Validation Results to CSV"
puts "=" * 50

# Get the latest interaction results (what you were extracting manually)
latest_interaction = OpenAIInteraction.order(:created_at).last

if latest_interaction&.response_body.present?
  # Extract the results using the method you were using manually
  raw_text = latest_interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
  
  # Clean up the JSON (remove ```json wrapper)
  json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
  results = JSON.parse(json_text)
  
  puts "📊 Found #{results.length} skills in latest interaction"
  puts ""
  
  # Export to CSV using our new method
  filename = "latest_skills_validation.csv"
  filepath = Gemini::Skills.export_to_csv(results: results, filename: filename)
  
  if filepath
    puts "✅ CSV exported successfully!"
    puts "📁 File location: #{filepath}"
    puts ""
    
    # Show a preview of what was exported
    puts "📋 Preview of first 5 skills:"
    results.first(5).each_with_index do |skill, index|
      status = skill['is_valid'] ? '✅' : '❌'
      clusters = skill['clusters'].present? ? skill['clusters'].join(', ') : 'none'
      puts "   #{index + 1}. #{status} #{skill['original_input']} → #{skill['canonical_name']} (clusters: #{clusters})"
    end
    
    puts "..." if results.length > 5
    puts ""
    puts "🎯 Open the CSV file to see all #{results.length} skills!"
  else
    puts "❌ Failed to export CSV"
  end
else
  puts "❌ No results found in latest interaction"
end
