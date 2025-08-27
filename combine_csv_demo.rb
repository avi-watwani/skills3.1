#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🔀 Combining Skills from Multiple Interactions"
puts "=" * 50

# Check how many interactions we have
total_interactions = OpenAIInteraction.count
puts "📊 Total interactions in database: #{total_interactions}"

# Get the last 2 interactions and show their info
last_interactions = OpenAIInteraction.order(:created_at).last(2)
puts "📋 Last 2 interactions:"
last_interactions.each_with_index do |interaction, index|
  puts "   #{index + 1}. ID: #{interaction.id}, Created: #{interaction.created_at.strftime('%Y-%m-%d %H:%M')}"
  
  # Try to count skills in each interaction
  begin
    raw_text = interaction.response_body['candidates'].first.dig('content', 'parts').first['text']
    json_text = raw_text.gsub(/```json\n?/, '').gsub(/```\n?$/, '').strip
    results = JSON.parse(json_text)
    puts "      Skills count: #{results.length}"
  rescue
    puts "      Skills count: Unable to parse"
  end
end

puts ""
puts "🚀 Combining last 2 interactions into single CSV..."

# Export combined CSV
csv_path = Gemini::Skills.export_combined_to_csv(count: 2, filename: 'combined_40_skills.csv')

if csv_path
  puts "✅ Combined CSV exported to: #{File.basename(csv_path)}"
  
  # Count total skills in the combined file
  require 'csv'
  rows = CSV.read(csv_path, headers: true)
  puts "📈 Total skills in combined CSV: #{rows.length}"
  
  # Show breakdown by validity
  valid_skills = rows.select { |row| row['Is Valid'] == 'true' }
  invalid_skills = rows.select { |row| row['Is Valid'] == 'false' }
  review_needed = rows.select { |row| row['Requires Review'] == 'true' }
  
  puts ""
  puts "📊 Combined Statistics:"
  puts "   ✅ Valid skills: #{valid_skills.length}"
  puts "   ❌ Invalid skills: #{invalid_skills.length}"
  puts "   🔍 Need review: #{review_needed.length}"
  puts "   📈 Validation rate: #{(valid_skills.length.to_f / rows.length * 100).round(1)}%"
  
  puts ""
  puts "📋 Sample from combined CSV (first 3 skills):"
  rows.first(3).each_with_index do |row, index|
    status = row['Is Valid'] == 'true' ? '✅' : '❌'
    puts "   #{index + 1}. #{status} #{row['Original Input']} → #{row['Canonical Name']}"
    puts "      Clusters: #{row['Cluster Names']}" if row['Cluster Names'].present?
  end
  
else
  puts "❌ Failed to create combined CSV"
end
