#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'config/environment'
require 'csv'

class SkillClustersPopulator
  def initialize
    @updated_count = 0
    @not_found_count = 0
    @error_count = 0
    @processed_files = []
    @errors = []
  end

  def populate_from_csv_files
    puts "Starting population of skill_clusters table from CSV files..."
    puts "=" * 60

    # Find all CSV files matching the pattern
    csv_files = Dir.glob("skills_details_domain_*.csv").sort

    if csv_files.empty?
      puts "❌ No CSV files found matching pattern 'skills_details_domain_*.csv'"
      return
    end

    puts "Found #{csv_files.length} CSV files to process:"
    csv_files.each { |file| puts "  - #{file}" }
    puts

    # Process each CSV file
    csv_files.each do |file|
      process_csv_file(file)
    end

    # Print summary
    print_summary
  end

  private

  def process_csv_file(filepath)
    puts "Processing: #{filepath}"

    # Extract domain_id and cluster_id from filename
    # Expected format: skills_details_domain_X_cluster_Y.csv
    match = filepath.match(/skills_details_domain_(\d+)_cluster_(\d+)\.csv/)

    unless match
      error_msg = "Cannot parse domain_id and cluster_id from filename: #{filepath}"
      puts "  ❌ #{error_msg}"
      @errors << error_msg
      @error_count += 1
      return
    end

    domain_id = match[1].to_i
    cluster_id = match[2].to_i

    puts "  📂 Domain ID: #{domain_id}, Cluster ID: #{cluster_id}"

    file_updated_count = 0
    file_not_found_count = 0

    begin
      CSV.foreach(filepath, headers: true, header_converters: :symbol) do |row|
        skill_id = row[:skill_id].to_i
        outcome_id = row[:outcome_id].to_i
        merge_with_skill_id = parse_merge_with_skill_id(row[:merge_with_skill_id])
        reason = row[:reason]&.strip

        # Find the SkillCluster record
        skill_cluster = SkillCluster.find_by(skill_id: skill_id, cluster_id: cluster_id)

        if skill_cluster
          # Update the merge result columns
          skill_cluster.update!(
            outcome_id: outcome_id,
            merge_with_skill_id: merge_with_skill_id,
            reason: reason
          )
          file_updated_count += 1

          if file_updated_count % 100 == 0
            puts "    ✅ Updated #{file_updated_count} records so far..."
          end
        else
          puts "    ⚠️  SkillCluster not found for skill_id: #{skill_id}, cluster_id: #{cluster_id}"
          file_not_found_count += 1
          @not_found_count += 1
        end
      end

      puts "  ✅ Completed: #{file_updated_count} updated, #{file_not_found_count} not found"
      @updated_count += file_updated_count
      @processed_files << {
        file: filepath,
        domain_id: domain_id,
        cluster_id: cluster_id,
        updated: file_updated_count,
        not_found: file_not_found_count
      }
    rescue => e
      error_msg = "Error processing #{filepath}: #{e.message}"
      puts "  ❌ #{error_msg}"
      @errors << error_msg
      @error_count += 1
    end

    puts
  end

  def parse_merge_with_skill_id(value)
    # Handle empty strings, nil, or whitespace-only values
    return nil if value.blank? || value.to_s.strip.empty?

    # Convert to integer if it's a valid number
    value.to_i if value.to_s.strip.match?(/^\d+$/)
  end

  def print_summary
    puts "=" * 60
    puts "📊 POPULATION SUMMARY"
    puts "=" * 60
    puts "Files processed: #{@processed_files.length}"
    puts "Total records updated: #{@updated_count}"
    puts "Records not found: #{@not_found_count}"
    puts "Files with errors: #{@error_count}"
    puts

    if @processed_files.any?
      puts "📁 File Details:"
      @processed_files.each do |file_info|
        puts "  #{file_info[:file]}"
        puts "    Domain: #{file_info[:domain_id]}, Cluster: #{file_info[:cluster_id]}"
        puts "    Updated: #{file_info[:updated]}, Not Found: #{file_info[:not_found]}"
      end
      puts
    end

    if @errors.any?
      puts "❌ Errors encountered:"
      @errors.each { |error| puts "  - #{error}" }
      puts
    end

    # Show some sample updated records
    if @updated_count > 0
      puts "📋 Sample of updated records:"
      SkillCluster.where.not(outcome_id: nil).limit(5).each do |sc|
        puts "  SkillCluster ID: #{sc.id}, Skill: #{sc.skill_id}, Cluster: #{sc.cluster_id}"
        puts "    Outcome: #{sc.outcome_id}, Merge With: #{sc.merge_with_skill_id || 'N/A'}"
        puts "    Reason: #{sc.reason&.truncate(60) || 'N/A'}"
      end
    end

    puts "=" * 60
    puts @updated_count > 0 ? "✅ Population completed successfully!" : "⚠️  No records were updated."
  end
end

# Run the population if this script is executed directly
if __FILE__ == $0
  populator = SkillClustersPopulator.new
  populator.populate_from_csv_files
end
