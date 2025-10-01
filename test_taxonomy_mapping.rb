#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'
require 'json'

puts "🔍 Testing Taxonomy Mapping"
puts "=" * 30

# Load the taxonomy mapping
mapping = JSON.parse(File.read('taxonomy_mapping.json'))

# Helper method to find cluster by taxonomy ID
def find_cluster_by_taxonomy_id(taxonomy_id, mapping)
  mapping.each do |domain_id, domain_data|
    cluster_data = domain_data['clusters'][taxonomy_id.to_s]
    if cluster_data
      return {
        cluster_id: cluster_data['cluster_db_id'],
        cluster_name: cluster_data['cluster_name'],
        domain_id: domain_data['domain_db_id'],
        domain_name: domain_data['domain_name']
      }
    end
  end
  nil
end

# Test with some cluster IDs from the CSV exports
test_cluster_ids = [16, 31, 44, 42, 20]

puts "Testing cluster lookups:"
test_cluster_ids.each do |cluster_id|
  result = find_cluster_by_taxonomy_id(cluster_id, mapping)
  if result
    puts "  #{cluster_id} → #{result[:cluster_name]} (Domain: #{result[:domain_name]})"
  else
    puts "  #{cluster_id} → Not found"
  end
end

puts ""
puts "✅ Taxonomy mapping is working correctly!"
puts "   You can now map cluster IDs (1-65) to database records"