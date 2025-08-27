#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🎯 Enhanced CSV Export Demo with Cluster & Domain Information"
puts "=" * 65

# Export the latest validation to CSV with enhanced data
csv_path = Gemini::Skills.export_latest_to_csv(filename: 'enhanced_skills_demo.csv')

if csv_path
  puts "✅ Enhanced CSV exported to: #{File.basename(csv_path)}"
  
  # Read and display the first few rows in a formatted way
  require 'csv'
  
  rows = CSV.read(csv_path, headers: true)
  puts "📊 Total skills: #{rows.length}"
  puts ""
  
  puts "📋 Sample of enhanced data (first 3 skills):"
  puts "-" * 65
  
  rows.first(3).each_with_index do |row, index|
    puts "#{index + 1}. #{row['Original Input']} → #{row['Canonical Name']}"
    puts "   Valid: #{row['Is Valid']} | Review: #{row['Requires Review']}"
    puts "   Clusters: #{row['Clusters']}" if row['Clusters'].present?
    puts "   Cluster Names: #{row['Cluster Names']}" if row['Cluster Names'].present?
    puts "   Domain IDs: #{row['Domain IDs']}" if row['Domain IDs'].present?
    puts "   Domain Names: #{row['Domain Names']}" if row['Domain Names'].present?
    puts ""
  end
  
  puts "💡 The CSV now includes:"
  puts "   • Original skill input"
  puts "   • Canonical skill name"
  puts "   • Validation status"
  puts "   • Review requirements"
  puts "   • Cluster IDs (numbers)"
  puts "   • Cluster Names (descriptive)"
  puts "   • Domain IDs (numbers)"
  puts "   • Domain Names (descriptive)"
  
else
  puts "❌ Failed to export CSV"
end
