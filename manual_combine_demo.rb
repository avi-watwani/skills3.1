#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🔧 Manual Approach: Combining Multiple Interactions"
puts "=" * 55

# Get results manually from last 2 interactions (like you were doing)
last_interactions = OpenAIInteraction.last(2)
all_results = []

puts "📋 Processing interactions manually..."

last_interactions.each_with_index do |interaction, index|
  puts "Processing interaction #{index + 1} (ID: #{interaction.id})..."
  
  raw_text = interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
  json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
  results = JSON.parse(json_text)
  
  puts "  Found #{results.length} skills"
  all_results.concat(results)
end

puts ""
puts "🎯 Combined #{all_results.length} skills from #{last_interactions.length} interactions"

# Export to CSV using your preferred approach
csv_path = Gemini::Skills.export_to_csv(results: all_results, filename: 'manual_combined_skills.csv')

puts "✅ Manual combined CSV exported to: #{File.basename(csv_path)}"

# Show some stats
valid_count = all_results.count { |skill| skill['is_valid'] }
invalid_count = all_results.count { |skill| !skill['is_valid'] }

puts ""
puts "📊 Manual Combination Results:"
puts "   Total skills: #{all_results.length}"
puts "   Valid: #{valid_count}"
puts "   Invalid: #{invalid_count}"
puts "   Validation rate: #{(valid_count.to_f / all_results.length * 100).round(1)}%"

puts ""
puts "📋 First 5 skills from manual combination:"
all_results.first(5).each_with_index do |skill, index|
  status = skill['is_valid'] ? '✅' : '❌'
  clusters = skill['clusters'].present? ? skill['clusters'].join(', ') : 'none'
  puts "   #{index + 1}. #{status} #{skill['original_input']} → #{skill['canonical_name']} (#{clusters})"
end
