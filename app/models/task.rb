class Task < ActiveRecord::Base
  include Authority::Abilities
  self.authorizer_name = 'TaskAuthorizer'

  include Concerns::DateWriter

  acts_as_list scope: :group

  belongs_to :group
  belongs_to :person
  belongs_to :site
  has_many :comments, as: :commentable, dependent: :destroy

  scope_by_site_id

  scope :incomplete, -> { where(completed: false) }

  validates :name, :group_id, presence: true

  after_save :update_counter_cache
  after_destroy :update_counter_cache
  
  def person_id_or_all=id
    (self.group_scope = !!(id == "All")) ? self.person_id = nil : self.person_id = id
    id
  end
  def person_id_or_all
    group_scope ? "All" : person_id
  end
  def update_counter_cache
    self.person.update_attribute(:incomplete_tasks_count, self.person.tasks.incomplete.count) if self.person.present?
  end
  date_writer :duedate
end
