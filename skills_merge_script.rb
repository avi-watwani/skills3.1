# frozen_string_literal: true
require_relative 'config/environment'
require 'csv'

# Enhanced Skills Merge Processing Script
puts "=" * 80
puts "SKILLS MERGE PROCESSING - ENHANCED VERSION"
puts "=" * 80

# Initialize counters and tracking
processed = 0
validation_failures = 0
exceptions = 0
total_skills_processed = 0
error_clusters = []
start_time = Time.now

# Get processing scope
total_domains = Domain.count
total_clusters = Domain.joins(:clusters).count('clusters.id')
puts "Processing scope: #{total_domains} domains, #{total_clusters} clusters"
puts "Started at: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
puts

Domain.all.each_with_index do |domain, domain_index|
  puts "\n[#{domain_index + 1}/#{total_domains}] Processing Domain: #{domain.name}"
  domain_clusters = domain.clusters.count

  domain.clusters.each_with_index do |cluster, cluster_index|
    cluster_progress = "#{cluster_index + 1}/#{domain_clusters}"
    print "  [#{cluster_progress}] #{cluster.name}... "

    valid_skills = cluster.skills.where(is_valid: true).first(150)

    # Skip if no skills in this cluster
    if valid_skills.empty?
      puts "SKIPPED (no valid skills)"
      next
    end

    skills_count = valid_skills.count
    total_skills_processed += skills_count
    print "#{skills_count} skills... "

    # Build the input structure
    cluster_data = {
      domain: domain.name,
      sub_domain: cluster.name,
      skills: valid_skills.map do |skill|
        {
          skill_id: skill.id,
          skill_name: skill.canonical_name
        }
      end
    }
    output_filename = "skills_details_domain_#{domain.id}_cluster_#{cluster.id}.csv"

    begin
      merge_start = Time.now
      skills_merger = Gemini::Skills.new
      skills_merger.merge_skills(cluster_data, output_filename)
      merge_time = Time.now - merge_start

      # Check for validation failures using enhanced error handling
      if skills_merger.validation_failed?
        validation_failures += 1
        puts "VALIDATION FAILED (#{merge_time.round(2)}s)"
        puts "    Reason: #{skills_merger.last_validation_error}"

        # Add detailed validation error info
        error_clusters.concat(skills_merger.error_clusters) if skills_merger.error_clusters.any?
      elsif skills_merger.error_clusters.any?
        # Other types of errors (shouldn't happen with current implementation, but safety check)
        validation_failures += 1
        puts "ERROR (#{merge_time.round(2)}s)"
        error_clusters.concat(skills_merger.error_clusters)
      else
        processed += 1
        puts "SUCCESS (#{merge_time.round(2)}s)"
      end
    rescue StandardError => e
      exceptions += 1
      puts "EXCEPTION (#{e.class})"
      puts "    Error: #{e.message}"

      # Add exception info with enhanced details
      exception_info = {
        domain: domain.name,
        cluster: cluster.name,
        error_type: 'script_exception',
        error_message: e.message,
        exception_class: e.class.to_s,
        skills_count: skills_count
      }

      # Try to get validation error if the merger was created
      if defined?(skills_merger) && skills_merger.respond_to?(:last_validation_error) && skills_merger.last_validation_error
        exception_info[:validation_error] = skills_merger.last_validation_error
      end

      error_clusters << exception_info
    end

    # Add a small delay to be nice to the API
    sleep(1)
  end
end

# Final Summary
end_time = Time.now
total_time = end_time - start_time
total_errors = validation_failures + exceptions

puts "\n" + "=" * 80
puts "PROCESSING COMPLETED"
puts "=" * 80
puts "Started: #{start_time.strftime('%Y-%m-%d %H:%M:%S')}"
puts "Finished: #{end_time.strftime('%Y-%m-%d %H:%M:%S')}"
puts "Duration: #{total_time.round(2)} seconds"
puts
puts "RESULTS SUMMARY:"
puts "  ✅ Successfully processed: #{processed} clusters"
puts "  ⚠️  Validation failures: #{validation_failures} clusters"
puts "  ❌ Exceptions: #{exceptions} clusters"
puts "  📊 Total skills processed: #{total_skills_processed} skills"
puts "  📁 Total clusters attempted: #{processed + total_errors}"
puts

if total_errors > 0
  success_rate = (processed.to_f / (processed + total_errors) * 100).round(1)
  puts "Success Rate: #{success_rate}%"
  puts
end

# Detailed Error Analysis
if error_clusters.any?
  puts "🔍 DETAILED ERROR ANALYSIS:"
  puts "-" * 50

  # Group errors by type
  validation_errors = error_clusters.select { |e| e[:error_type] == 'validation_failed' }
  exception_errors = error_clusters.select { |e| e[:error_type] == 'script_exception' }

  if validation_errors.any?
    puts "\n📋 VALIDATION FAILURES (#{validation_errors.count}):"
    validation_errors.each_with_index do |error_info, index|
      puts "#{index + 1}. #{error_info[:domain]} → #{error_info[:cluster]}"
      puts "   💡 Reason: #{error_info[:error_message]}"
      puts "   📊 Skills: #{error_info[:skills_count]}" if error_info[:skills_count]
      puts
    end
  end

  if exception_errors.any?
    puts "\n⚡ EXCEPTIONS (#{exception_errors.count}):"
    exception_errors.each_with_index do |error_info, index|
      puts "#{index + 1}. #{error_info[:domain]} → #{error_info[:cluster]}"
      puts "   🚨 Error: #{error_info[:error_message]}"
      puts "   🔧 Class: #{error_info[:exception_class]}"
      puts "   📊 Skills: #{error_info[:skills_count]}" if error_info[:skills_count]
      puts "   🔍 Validation: #{error_info[:validation_error]}" if error_info[:validation_error]
      puts
    end
  end

  # Summary of most common error types
  puts "\n📈 ERROR PATTERN ANALYSIS:"
  error_messages = error_clusters.map { |e| e[:error_message] }
  message_counts = error_messages.each_with_object(Hash.new(0)) { |msg, hash| hash[msg] += 1 }

  puts "Most common error messages:"
  message_counts.sort_by { |_, count| -count }.first(5).each do |message, count|
    puts "  • #{count}x: #{message.truncate(80)}"
  end
else
  puts "🎉 NO ERRORS OCCURRED!"
  puts "All clusters processed successfully!"
end

# CSV Files Summary
csv_files = Dir.glob("skills_details_domain_*.csv")
if csv_files.any?
  puts "\n📁 Generated CSV Files (#{csv_files.count}):"
  total_size = csv_files.sum { |file| File.size(file) }
  puts "  Total size: #{(total_size / 1024.0).round(1)} KB"
  puts "  Files: #{csv_files.first(3).join(', ')}#{csv_files.count > 3 ? '...' : ''}"
end

puts "\n" + "=" * 80
