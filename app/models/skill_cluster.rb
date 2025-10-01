class SkillCluster < ApplicationRecord
  belongs_to :skill
  belongs_to :cluster
  
  validates :skill_id, uniqueness: { scope: :cluster_id }
end
