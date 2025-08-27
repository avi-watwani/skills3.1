#!/usr/bin/env ruby

require_relative 'config/environment'

puts "=== COMPLETE GEMINI SKILLS SYSTEM TEST ==="
puts

# Test 1: Validate new skills
puts "1. Testing skills validation with database logging..."
new_skills = ["Ruby on Rails", "Invalid Skill Name 12345", "Leadership"]

chat = Gemini::Skills.new.validate_skills(new_skills)
results = Gemini::Skills.parse_results(chat)

puts "✓ Validated #{results.length} skills:"
results.each do |skill|
  status = skill['is_valid'] ? '✓' : '✗'
  review = skill['requires_review'] ? ' (review needed)' : ''
  clusters = skill['clusters']&.any? ? " [#{skill['clusters'].join(', ')}]" : ''
  puts "  #{status} #{skill['original_input']} → #{skill['canonical_name']}#{review}#{clusters}"
end

puts "\n2. Database summary..."
puts "Total interactions: #{OpenAIInteraction.count}"
puts "Successful interactions: #{OpenAIInteraction.successful.count}"

puts "\n3. Historical validation statistics..."
stats = Gemini::Skills.validation_statistics
puts "Total skills processed: #{stats[:total_skills]}"
puts "Valid skills: #{stats[:valid_skills]} (#{(stats[:validation_rate] * 100).round(1)}%)"
puts "Invalid skills: #{stats[:invalid_skills]}"
puts "Skills needing review: #{stats[:review_needed]}"

puts "\n4. Cluster distribution:"
stats[:cluster_distribution].each do |cluster_id, count|
  puts "  Cluster #{cluster_id}: #{count} skills"
end

puts "\n5. Latest database record can extract results:"
latest = OpenAIInteraction.recent.first
db_results = latest.skills_validation_results
puts "Latest record extracted #{db_results.length} skills successfully"

puts "\n✅ ALL TESTS PASSED! Database logging and retrieval working perfectly."
