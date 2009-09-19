# == Schema Information
#
# Table name: checkin_times
#
#  id           :integer       not null, primary key
#  weekday      :integer       
#  time         :integer       
#  the_datetime :datetime      
#  created_at   :datetime      
#  updated_at   :datetime      
#

class CheckinTime < ActiveRecord::Base
  has_many :group_times, :dependent => :destroy
  has_many :groups, :through => :group_times, :order => 'group_times.ordering'
  
  named_scope :recurring,        :conditions => ["the_datetime is null"]
  named_scope :upcoming_singles, :conditions => ["the_datetime is not null and the_datetime >= #{sql_now}"]
  
  self.skip_time_zone_conversion_for_attributes = [:the_datetime]
  
  scope_by_site_id
  
  def validate
    if weekday
      if time.nil?
        errors.add_to_base('The time is not formatted correctly. Try something like "6:00 p.m."')
      end
      if the_datetime
        errors.add_to_base('You cannot specify a specific date and time and a recurring time together.')
      end
    end
    if not weekday and not the_datetime
      errors.add_to_base('You must specify either a recurring date and time or a specific date and time.')
    end
  end
  
  def time=(t)
    if t.to_s.strip.any? && t = Time.parse(t) rescue nil
      write_attribute(:time, t.strftime('%H%M').to_i)
    else
      write_attribute(:time, nil)
    end
  end
end
