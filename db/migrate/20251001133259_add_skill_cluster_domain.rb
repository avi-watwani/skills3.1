# frozen_string_literal: true

# This migration adds tables for skills, clusters, domains, and the join table skill_clusters.
class AddSkillClusterDomain < ActiveRecord::Migration[5.0]
  def change
    # Domains table (Technology & IT, Design & Creative, etc.)
    create_table :domains do |t|
      t.string :name, null: false
      t.timestamps
    end

    # Clusters table (Software Development & Engineering, etc.)
    create_table :clusters do |t|
      t.string :name, null: false
      t.references :domain, foreign_key: true, null: false
      t.timestamps
    end

    # Skills table
    create_table :skills do |t|
      t.string :original_input, null: false
      t.string :canonical_name, null: false
      t.boolean :is_valid, null: false, default: false
      t.boolean :requires_review, null: false, default: false
      t.string :review_reason
      t.timestamps
    end

    # Join table for many-to-many relationship between skills and clusters
    create_table :skill_clusters do |t|
      t.references :skill, foreign_key: true, null: false
      t.references :cluster, foreign_key: true, null: false
      t.timestamps
    end

    # Indexes for performance
    add_index :skill_clusters, [:skill_id, :cluster_id], unique: true
    add_index :skills, :is_valid
    add_index :skills, :requires_review
  end
end
