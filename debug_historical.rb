#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "Debugging historical_results method..."

puts "OpenAIInteraction defined? #{defined?(OpenAIInteraction)}"
puts "OpenAIInteraction.count: #{OpenAIInteraction.count}"
puts "OpenAIInteraction.successful.count: #{OpenAIInteraction.successful.count}"

puts "\nChecking individual records:"
OpenAIInteraction.successful.each do |interaction|
  puts "Record #{interaction.id}:"
  puts "  Status: #{interaction.http_status_code}"
  puts "  Successful?: #{interaction.successful?}"
  results = interaction.skills_validation_results
  puts "  Results count: #{results.length}"
  puts "  First result: #{results.first.inspect}" if results.any?
end

puts "\nDirect method test:"
results = Gemini::Skills.historical_results
puts "Historical results count: #{results.length}"

if results.any?
  puts "First result: #{results.first.inspect}"
else
  puts "No results found - debugging further..."
  
  # Test the method step by step
  all_results = []
  OpenAIInteraction.successful.each do |interaction|
    puts "Processing interaction #{interaction.id}..."
    results = interaction.skills_validation_results
    puts "  Got #{results.length} results"
    all_results.concat(results) if results.present?
  end
  puts "Total concatenated results: #{all_results.length}"
end
