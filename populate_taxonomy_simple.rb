#!/usr/bin/env ruby

# Load Rails environment
require_relative 'config/environment'

puts "🏗️  Populating Domains & Clusters from Taxonomy (Simple Version)"
puts "=" * 60

# Taxonomy data from the system prompt
taxonomy_data = [
  { id: 1, domain: "Technology & IT",
    clusters: [
      { id: 1, cluster: "Software Development & Engineering" },
      { id: 2, cluster: "DevOps & Cloud Infrastructure" },
      { id: 3, cluster: "Data Science, Analytics & AI" },
      { id: 4, cluster: "Cybersecurity & Information Security" },
      { id: 5, cluster: "IT Support & Network Administration" },
      { id: 6, cluster: "Enterprise Systems & Applications" },
      { id: 7, cluster: "Software Quality Assurance" },
      { id: 8, cluster: "Emerging Technologies & Innovation" }
    ]},
  { id: 2, domain: "Design & Creative",
    clusters: [
      { id: 9, cluster: "UX/UI Design & Research" },
      { id: 10, cluster: "Visual Design, Animation & 3D" },
      { id: 11, cluster: "Content Creation, Writing & Editing" },
      { id: 12, cluster: "Audio, Video & Media Production" },
      { id: 13, cluster: "Game Design & Development" },
      { id: 14, cluster: "Photography & Videography" }
    ]},
  { id: 3, domain: "Sales, Marketing & Customer Success",
    clusters: [
      { id: 15, cluster: "Sales & Business Development" },
      { id: 16, cluster: "Digital Marketing & Growth" },
      { id: 17, cluster: "Brand, Content & Communications Strategy" },
      { id: 18, cluster: "Market Research & Consumer Insights" },
      { id: 19, cluster: "Customer Success, Service & Support" }
    ]},
  { id: 4, domain: "Business, Finance & Legal",
    clusters: [
      { id: 20, cluster: "Finance & Accounting" },
      { id: 21, cluster: "Business Analysis & Intelligence" },
      { id: 22, cluster: "Strategy & Business Management" },
      { id: 23, cluster: "Legal, Risk & Compliance" },
      { id: 24, cluster: "Procurement & Vendor Management" },
      { id: 25, cluster: "Real Estate & Property Management" }
    ]},
  { id: 5, domain: "Human Resources & People Operations",
    clusters: [
      { id: 26, cluster: "Talent Acquisition & Recruitment" },
      { id: 27, cluster: "Compensation & Benefits" },
      { id: 28, cluster: "Employee Relations & Engagement" },
      { id: 29, cluster: "HR Operations & Compliance" },
      { id: 30, cluster: "Learning & Development" }
    ]},
  { id: 6, domain: "Leadership & Professional Development",
    clusters: [
      { id: 31, cluster: "Leadership & People Management" },
      { id: 32, cluster: "Project & Program Management" },
      { id: 33, cluster: "Coaching, Mentoring & Training" },
      { id: 34, cluster: "Communication & Interpersonal Skills" },
      { id: 35, cluster: "Personal Effectiveness & Productivity" },
      { id: 36, cluster: "Diversity, Equity, Inclusion & Belonging" },
      { id: 37, cluster: "Languages & Localization" }
    ]},
  { id: 7, domain: "Engineering, Manufacturing & Supply Chain",
    clusters: [
      { id: 38, cluster: "Mechanical, Electrical & Civil Engineering" },
      { id: 39, cluster: "Manufacturing & Production Operations" },
      { id: 40, cluster: "Supply Chain & Logistics" },
      { id: 41, cluster: "Lean, Six Sigma & Continuous Improvement" },
      { id: 42, cluster: "Health, Safety & Environment" },
      { id: 43, cluster: "Manufacturing Quality Control" },
      { id: 44, cluster: "Skilled Trades & Industrial Maintenance" },
      { id: 45, cluster: "Oil, Gas & Energy Engineering" },
      { id: 46, cluster: "Mining & Geosciences" },
      { id: 47, cluster: "Aviation & Aerospace" },
      { id: 48, cluster: "Marine & Maritime" }
    ]},
  { id: 8, domain: "Healthcare & Life Sciences",
    clusters: [
      { id: 49, cluster: "Clinical Care & Nursing" },
      { id: 50, cluster: "Biomedical Science & Pharmaceutical Research" },
      { id: 51, cluster: "Allied Health & Therapeutic Services" },
      { id: 52, cluster: "Public Health & Epidemiology" },
      { id: 53, cluster: "Health Informatics & Administration" },
      { id: 54, cluster: "Veterinary & Animal Health" }
    ]},
  { id: 9, domain: "Education & Human Services",
    clusters: [
      { id: 55, cluster: "Classroom Instruction & Tutoring" },
      { id: 56, cluster: "Curriculum & Instructional Design" },
      { id: 57, cluster: "Special Education & Student Support" },
      { id: 58, cluster: "Public Administration & Policy" },
      { id: 59, cluster: "Community Outreach & Social Work" },
      { id: 60, cluster: "Information & Library Science" }
    ]},
  { id: 10, domain: "Hospitality, Retail & Events",
    clusters: [
      { id: 61, cluster: "Culinary & Food Services" },
      { id: 62, cluster: "Retail & E-Commerce Operations" },
      { id: 63, cluster: "Hotel, Travel & Tourism Management" },
      { id: 64, cluster: "Event Planning & Management" },
      { id: 65, cluster: "Sports, Fitness & Wellness" }
    ]}
]

# Check current state
existing_domains = Domain.count
existing_clusters = Cluster.count

puts "📊 Current state:"
puts "   Domains: #{existing_domains}"
puts "   Clusters: #{existing_clusters}"
puts ""

# Create a mapping to store taxonomy IDs as a reference
# We'll store this information in case we want to add taxonomy_id columns later
taxonomy_mapping = {}

# Populate domains and clusters
domains_created = 0
clusters_created = 0

puts "🚀 Processing taxonomy data..."

ActiveRecord::Base.transaction do
  taxonomy_data.each do |domain_data|
    # Create domain (skip if already exists by name)
    domain = Domain.find_or_create_by(name: domain_data[:domain]) do |d|
      puts "   ✅ Created domain: #{domain_data[:domain]}"
      domains_created += 1
    end
    
    # Store the mapping for future reference
    taxonomy_mapping[domain_data[:id]] = { domain: domain, clusters: {} }
    
    # Create clusters for this domain
    domain_data[:clusters].each do |cluster_data|
      cluster = Cluster.find_or_create_by(
        name: cluster_data[:cluster], 
        domain: domain
      ) do |c|
        puts "      ✅ Created cluster: #{cluster_data[:cluster]}"
        clusters_created += 1
      end
      
      # Store the cluster mapping
      taxonomy_mapping[domain_data[:id]][:clusters][cluster_data[:id]] = cluster
    end
  end
end

puts ""
puts "🎉 Population completed successfully!"
puts ""
puts "📊 Summary:"
puts "   Domains created: #{domains_created}"
puts "   Clusters created: #{clusters_created}"
puts ""
puts "📈 Final counts:"
puts "   Total domains: #{Domain.count}"
puts "   Total clusters: #{Cluster.count}"
puts ""

# Verification
puts "🔍 Verification:"
taxonomy_data.each do |domain_data|
  domain = Domain.find_by(name: domain_data[:domain])
  if domain
    cluster_count = domain.clusters.count
    expected_count = domain_data[:clusters].length
    status = cluster_count == expected_count ? "✅" : "❌"
    puts "   #{status} #{domain.name}: #{cluster_count}/#{expected_count} clusters"
  else
    puts "   ❌ Missing domain: #{domain_data[:domain]}"
  end
end

puts ""
puts "💡 Taxonomy mapping created for #{taxonomy_mapping.keys.length} domains"
puts "   This can be used to map cluster IDs (1-65) to actual Cluster records"
puts ""
puts "✨ Database is ready for skills validation!"

# Save mapping to a file for future reference
puts ""
puts "💾 Saving taxonomy mapping to file..."
mapping_file = 'taxonomy_mapping.json'
File.open(mapping_file, 'w') do |f|
  # Convert ActiveRecord objects to simple hash for JSON serialization
  simple_mapping = {}
  taxonomy_mapping.each do |domain_id, data|
    simple_mapping[domain_id] = {
      domain_db_id: data[:domain].id,
      domain_name: data[:domain].name,
      clusters: {}
    }
    data[:clusters].each do |cluster_id, cluster|
      simple_mapping[domain_id][:clusters][cluster_id] = {
        cluster_db_id: cluster.id,
        cluster_name: cluster.name
      }
    end
  end
  f.write(JSON.pretty_generate(simple_mapping))
end
puts "   Saved to: #{mapping_file}"