#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== Gemini Skills Validation Statistics ==="
puts

stats = Gemini::Skills.validation_statistics
puts JSON.pretty_generate(stats)

puts "\n=== Historical Results Sample ==="
results = Gemini::Skills.historical_results
puts "Total historical skills: #{results.length}"

if results.any?
  puts "\nFirst 5 skills:"
  results.first(5).each_with_index do |skill, index|
    status = skill['is_valid'] ? '✓ VALID' : '✗ INVALID'
    review = skill['requires_review'] ? ' (REVIEW NEEDED)' : ''
    clusters = skill['clusters']&.any? ? " [clusters: #{skill['clusters'].join(', ')}]" : ' [no clusters]'
    
    puts "#{index + 1}. #{skill['original_input']} → #{skill['canonical_name']} - #{status}#{review}#{clusters}"
  end
end
