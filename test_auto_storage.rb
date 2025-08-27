#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Test batch of skills
batch = ["Python", "Data Analysis", "Project Management"]

puts "🧪 Testing automatic database storage..."
puts "Skills to validate: #{batch.inspect}"
puts ""

# Check database count before
initial_count = OpenAIInteraction.count
puts "📊 Initial database count: #{initial_count}"

# Run validation with automatic storage
puts "🚀 Running skills validation..."
chat = Gemini::Skills.new.validate_skills(batch)

# Wait a moment for processing
sleep(1)

# Check database count after
final_count = OpenAIInteraction.count
puts "📊 Final database count: #{final_count}"
puts "📈 New records created: #{final_count - initial_count}"

# Verify the latest record
if final_count > initial_count
  latest_record = OpenAIInteraction.order(:created_at).last
  puts ""
  puts "✅ Latest database record:"
  puts "   - ID: #{latest_record.id}"
  puts "   - HTTP Status: #{latest_record.http_status_code}"
  puts "   - Request: #{latest_record.request_body}"
  puts "   - Response present: #{latest_record.response_body.present?}"
  
  # Try to parse results from database
  if latest_record.response_body.present?
    puts ""
    puts "🔍 Parsing results from database..."
    parsed_results = latest_record.skills_validation_results
    if parsed_results.present?
      puts "✅ Successfully parsed #{parsed_results.length} results from database"
      parsed_results.each_with_index do |result, index|
        puts "   #{index + 1}. #{result['original_input']} → #{result['canonical_name']} (valid: #{result['is_valid']})"
      end
    else
      puts "⚠️  No parsed results found"
    end
  end
else
  puts "❌ No new records created - automatic storage may have failed"
end

puts ""
puts "🎯 Test completed!"
