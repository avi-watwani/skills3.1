class AddColumnsToSkillClusters < ActiveRecord::Migration[5.0]
  def change
    add_column :skill_clusters, :outcome_id, :integer
    add_column :skill_clusters, :merge_with_skill_id, :integer
    add_column :skill_clusters, :reason, :text

    # Add indexes for better query performance
    add_index :skill_clusters, :outcome_id
    add_index :skill_clusters, :merge_with_skill_id
  end
end
