#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# Validate skills (automatically stores in database)
batch = ["Aviwashere", "Data Analysis", "Amazon Web Services"]
Gemini::Skills.new.validate_skills(batch)

# Retrieve results from database - use skills_validations scope for clean records
latest = OpenAIInteraction.skills_validations.successful.order(:created_at).last
results = latest.skills_validation_results

# Process results
results.each do |skill|
  status = skill['is_valid'] ? '✅' : '❌'
  clusters = skill['clusters'].present? ? " (clusters: #{skill['clusters'].join(', ')})" : ""
  puts "#{status} #{skill['original_input']} → #{skill['canonical_name']}#{clusters}"
end

# Show the clean request format
puts "\n📝 Skills that were validated: #{latest.request_body.inspect}"
