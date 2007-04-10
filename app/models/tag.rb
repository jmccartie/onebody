class Tag < ActiveRecord::Base
  belongs_to :verse
  has_and_belongs_to_many :verses
  has_and_belongs_to_many :recipes
  #has_and_belongs_to_many :groups
  has_and_belongs_to_many :songs
  acts_as_logger LogItem
  paranoid_attributes :name
end
