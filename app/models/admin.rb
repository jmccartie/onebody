# == Schema Information
# Schema version: 1
#
# Table name: admins
#
#  id                     :integer       not null, primary key
#  manage_publications    :boolean       
#  manage_log             :boolean       
#  manage_music           :boolean       
#  view_hidden_properties :boolean       
#  edit_profiles          :boolean       
#  manage_groups          :boolean       
#  manage_shares          :boolean       
#  manage_notes           :boolean       
#  manage_messages        :boolean       
#  view_hidden_profiles   :boolean       
#  manage_prayer_signups  :boolean       
#  manage_comments        :boolean       
#  manage_events          :boolean       
#  manage_recipes         :boolean       
#  manage_pictures        :boolean       
#  manage_access          :boolean       
#  view_log               :boolean       
#  manage_updates         :boolean       
#  created_at             :datetime      
#  updated_at             :datetime      
#  site_id                :integer       
#

class Admin < ActiveRecord::Base
  has_one :person
  belongs_to :site
  
  acts_as_scoped_globally 'site_id', 'Site.current.id'
  
  def self.privilege_columns
    columns.select { |c| !%w(id created_at updated_at).include? c.name }
  end
end
