#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Test with database logging
batch = ["Python", "JavaScript", "Team Leader"]

puts "Testing skills validation with database logging..."
puts "Skills: #{batch.join(', ')}"
puts "\n" + "="*50 + "\n"

begin
  # Before validation - check current count
  initial_count = OpenAIInteraction.count
  puts "Initial database records: #{initial_count}"
  
  # Run validation
  chat = Gemini::Skills.new.validate_skills(batch)
  results = Gemini::Skills.parse_results(chat)
  
  # After validation - check new count
  final_count = OpenAIInteraction.count
  puts "Final database records: #{final_count}"
  puts "New records created: #{final_count - initial_count}"
  
  if results.present?
    puts "\n✓ Skills validation successful!"
    puts "Results:"
    puts JSON.pretty_generate(results)
    
    # Show the latest database record
    latest_record = OpenAIInteraction.recent.first
    if latest_record
      puts "\n" + "="*50
      puts "LATEST DATABASE RECORD:"
      puts "ID: #{latest_record.id}"
      puts "Status Code: #{latest_record.http_status_code}"
      puts "Created: #{latest_record.created_at}"
      puts "Request Body: #{latest_record.request_body.class}"
      puts "Response Body: #{latest_record.response_body.class}"
      
      # Test the helper method
      db_results = latest_record.skills_validation_results
      puts "Extracted results from DB: #{db_results.length} skills"
      
      if db_results.present?
        puts "\nDB EXTRACTED RESULTS:"
        puts JSON.pretty_generate(db_results)
      end
    end
  else
    puts "⚠ No results returned"
  end
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
end
