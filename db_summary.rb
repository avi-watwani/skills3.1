#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "=== OpenAI Interactions Database Summary ==="
puts

# Show basic stats
total_records = OpenAIInteraction.count
successful_records = OpenAIInteraction.successful.count
failed_records = OpenAIInteraction.failed.count

puts "Total records: #{total_records}"
puts "Successful (200-299): #{successful_records}"
puts "Failed: #{failed_records}"
puts

if total_records > 0
  puts "=== Recent Records ==="
  
  OpenAIInteraction.recent.limit(5).each_with_index do |record, index|
    puts "\n#{index + 1}. Record ID: #{record.id}"
    puts "   Status: #{record.http_status_code}"
    puts "   Created: #{record.created_at}"
    puts "   Request skills: #{record.request_body.dig('contents', 1, 'parts', 0, 'text')}"
    
    results = record.skills_validation_results
    if results.present?
      puts "   Validated #{results.length} skills:"
      results.each do |skill|
        status = skill['is_valid'] ? '✓' : '✗'
        review = skill['requires_review'] ? ' (needs review)' : ''
        puts "     #{status} #{skill['original_input']} → #{skill['canonical_name']}#{review}"
      end
    else
      puts "   No extractable results"
    end
  end
  
  puts "\n=== Skills Summary from All Records ==="
  all_skills = []
  
  OpenAIInteraction.successful.each do |record|
    skills = record.skills_validation_results
    all_skills.concat(skills) if skills.present?
  end
  
  if all_skills.present?
    valid_skills = all_skills.select { |s| s['is_valid'] }
    invalid_skills = all_skills.reject { |s| s['is_valid'] }
    review_needed = all_skills.select { |s| s['requires_review'] }
    
    puts "Total skills processed: #{all_skills.length}"
    puts "Valid skills: #{valid_skills.length}"
    puts "Invalid skills: #{invalid_skills.length}"
    puts "Skills needing review: #{review_needed.length}"
    
    # Show cluster distribution
    clusters = valid_skills.flat_map { |s| s['clusters'] || [] }.compact
    cluster_counts = clusters.each_with_object(Hash.new(0)) { |cluster, hash| hash[cluster] += 1 }
    
    if cluster_counts.any?
      puts "\nCluster distribution:"
      cluster_counts.sort_by { |k, v| -v }.each do |cluster_id, count|
        puts "  Cluster #{cluster_id}: #{count} skills"
      end
    end
  end
else
  puts "No records found. Run some skills validations first!"
end
