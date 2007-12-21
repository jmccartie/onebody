# == Schema Information
# Schema version: 86
#
# Table name: updates
#
#  id           :integer(11)   not null, primary key
#  person_id    :integer(11)   
#  first_name   :string(255)   
#  last_name    :string(255)   
#  home_phone   :integer(20)   
#  mobile_phone :integer(20)   
#  work_phone   :integer(20)   
#  fax          :integer(20)   
#  address1     :string(255)   
#  address2     :string(255)   
#  city         :string(255)   
#  state        :string(2)     
#  zip          :string(10)    
#  birthday     :datetime      
#  anniversary  :datetime      
#  created_at   :datetime      
#  complete     :boolean(1)    
#

class Update < ActiveRecord::Base
  belongs_to :person
  
  def do!
    raise 'Unauthorized' unless Person.logged_in.admin?(:manage_updates)
    %w(first_name last_name mobile_phone work_phone fax birthday anniversary).each do |attribute|
      person[attribute] = self[attribute] unless self[attribute].nil?
    end
    if person.save
      %w(home_phone address1 address2 city state zip).each do |attribute|
        person.family[attribute] = self[attribute] unless self[attribute].nil?
      end
      person.family.save
    else 
      false
    end
  end
end
