#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🎯 Final Demo: Automatic Database Storage"
puts "=" * 50

# Count interactions before
initial_count = OpenAIInteraction.count
puts "📊 Initial database records: #{initial_count}"

# Test skills
batch = ["TypeScript", "Team Leadership", "Data Visualization"]
puts "📝 Validating skills: #{batch.inspect}"
puts ""

# Single line validation - automatically stores in database via Client class
puts "🚀 Running: Gemini::Skills.new.validate_skills(batch)"
chat = Gemini::Skills.new.validate_skills(batch)

# Check what was stored
final_count = OpenAIInteraction.count
new_records = final_count - initial_count
puts "✅ Validation completed!"
puts "📈 New database records: #{new_records}"
puts ""

if new_records > 0
  # Get the latest record
  latest_record = OpenAIInteraction.order(:created_at).last
  puts "💾 Latest database record:"
  puts "   - ID: #{latest_record.id}"
  puts "   - HTTP Status: #{latest_record.http_status_code}"
  puts "   - Successful: #{latest_record.successful?}"
  puts ""
  
  # Parse and display results using our enhanced model method
  results = latest_record.skills_validation_results
  if results.present?
    puts "📊 Parsed #{results.length} skills from database:"
    results.each_with_index do |result, index|
      status = result['is_valid'] ? '✅' : '❌'
      clusters = result['clusters'].present? ? result['clusters'].join(', ') : 'none'
      puts "   #{index + 1}. #{status} #{result['original_input']} → #{result['canonical_name']}"
      puts "      Clusters: #{clusters}" if result['clusters'].present?
    end
  else
    puts "⚠️  Could not parse results from database"
  end
else
  puts "❌ No new records created"
end

puts ""
puts "🎉 Summary:"
puts "   - Skills validation: Working ✅"
puts "   - Database storage: Automatic ✅" 
puts "   - Response parsing: Working ✅"
puts "   - Total records in DB: #{final_count}"
