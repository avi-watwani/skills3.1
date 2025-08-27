#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🎯 Demonstrating Automatic Database Storage"
puts "=" * 50

# Define skills to validate
batch = ["JavaScript", "Machine Learning", "Leadership", "Cooking"]

puts "📝 Skills to validate: #{batch.inspect}"
puts ""

# Single line to validate and automatically store
puts "🚀 Running: chat = Gemini::Skills.new.validate_skills(batch)"
chat = Gemini::Skills.new.validate_skills(batch)

puts "✅ Validation completed!"
puts ""

# Show that it's automatically stored
latest_record = OpenAIInteraction.order(:created_at).last
puts "💾 Automatically stored in database:"
puts "   - Record ID: #{latest_record.id}"
puts "   - Request: #{latest_record.request_body}"
puts "   - Status: #{latest_record.successful? ? 'Success' : 'Failed'}"
puts ""

# Parse and display results
results = latest_record.skills_validation_results
puts "📊 Parsed Results:"
results.each_with_index do |result, index|
  status = result['is_valid'] ? '✅' : '❌'
  clusters = result['clusters'].present? ? result['clusters'].join(', ') : 'none'
  puts "   #{index + 1}. #{status} #{result['original_input']} → #{result['canonical_name']} (clusters: #{clusters})"
end

puts ""
puts "🎉 That's it! One line validates skills AND stores in database!"
puts ""
puts "📈 Database now contains #{OpenAIInteraction.count} total validation records"
