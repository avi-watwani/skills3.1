# frozen_string_literal: true
require_relative 'config/environment'
require 'csv'

puts "Starting skills merge processing for all clusters..."

Domain.all.each do |domain|
  domain.clusters.each do |cluster|
    puts "\nProcessing Domain: #{domain.name}, Cluster: #{cluster.name}"
    valid_skills = cluster.skills.where(is_valid: true)
    # Build the Input structure
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

    puts "  To process: skills_merger = Gemini::Skills.new; chat = skills_merger.merge_skills(JSON.parse(File.read('#{json_file}'), symbolize_names: true))"
  end
end

puts "\nFinished generating skill merge JSON files."
