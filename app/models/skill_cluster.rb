class SkillCluster < ApplicationRecord
  belongs_to :skill
  belongs_to :cluster
  belongs_to :outcome, optional: true
  
  validates :skill_id, uniqueness: { scope: :cluster_id }
end
