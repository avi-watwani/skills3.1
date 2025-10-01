class Cluster < ApplicationRecord
  belongs_to :domain
  has_many :skill_clusters, dependent: :destroy
  has_many :skills, through: :skill_clusters
  
  validates :taxonomy_id, presence: true, uniqueness: true
  validates :name, presence: true
end
