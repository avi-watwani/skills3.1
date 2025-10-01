class Skill < ApplicationRecord
  has_many :skill_clusters, dependent: :destroy
  has_many :clusters, through: :skill_clusters
  has_many :domains, through: :clusters
  
  validates :original_input, presence: true
  validates :canonical_name, presence: true
  validates :is_valid, inclusion: { in: [true, false] }
  validates :requires_review, inclusion: { in: [true, false] }
end
