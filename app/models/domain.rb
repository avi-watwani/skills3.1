class Domain < ApplicationRecord
  has_many :clusters, dependent: :destroy
  has_many :skills, through: :clusters
  
  validates :name, presence: true, uniqueness: true
end
