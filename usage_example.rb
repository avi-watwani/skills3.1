#!/usr/bin/env ruby

# Example: How to use the skills validation with automatic database storage

require_relative 'config/environment'

# Define your skills batch
batch = ["Python", "Communication", "Project Management"]

# One line to validate and automatically store in database
chat = Gemini::Skills.new.validate_skills(batch)

# That's it! The response is automatically stored in the OpenAIInteraction table
# You can retrieve and parse the results from the database:

# Get the latest validation
latest_validation = OpenAIInteraction.order(:created_at).last
results = latest_validation.skills_validation_results

# Process the results
results.each do |skill|
  if skill['is_valid']
    puts "✅ #{skill['original_input']} → #{skill['canonical_name']} (clusters: #{skill['clusters'].join(', ')})"
  else
    puts "❌ #{skill['original_input']} - not valid"
  end
end

# You can also get historical data
puts "\n📈 Historical Statistics:"
stats = Gemini::Skills.validation_statistics
puts "Total skills processed: #{stats[:total_skills]}"
puts "Validation rate: #{(stats[:validation_rate] * 100).round(1)}%"
