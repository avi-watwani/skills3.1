class Domain < ApplicationRecord
  has_many :clusters, dependent: :destroy
  has_many :skills, through: :clusters
  
  validates :taxonomy_id, presence: true, uniqueness: true
  validates :name, presence: true
end
