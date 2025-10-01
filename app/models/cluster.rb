class Cluster < ApplicationRecord
  belongs_to :domain
  has_many :skill_clusters, dependent: :destroy
  has_many :skills, through: :skill_clusters
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :domain_id }
end
