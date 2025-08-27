#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

# One-liner to export latest validation results to CSV
csv_path = Gemini::Skills.export_latest_to_csv

if csv_path
  puts "✅ Latest skills validation exported to: #{csv_path}"
  puts "📊 #{File.readlines(csv_path).count - 1} skills exported"
else
  puts "❌ Failed to export - no recent validation found"
end
