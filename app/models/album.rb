class Album < ActiveRecord::Base

  belongs_to :owner, polymorphic: true
  belongs_to :site
  has_many :pictures, dependent: :delete_all

  scope_by_site_id

  scope :join_group_memberships, -> { joins("inner join groups on groups.id = owner_id and owner_type = 'Group' inner join memberships on memberships.group_id = groups.id") }

  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:site_id, :owner_type, :owner_id]

  def cover
    pictures.order('cover desc, id').first
  end

  after_destroy :delete_stream_items

  def delete_stream_items
    StreamItem.destroy_all(streamable_type: 'Album', streamable_id: id)
  end
end
