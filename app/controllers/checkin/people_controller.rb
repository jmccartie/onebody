class Checkin::PeopleController < ApplicationController
  unloadable
  
  def index
    select = 'families.id, families.barcode_id, people.family_id, people.id, people.first_name, people.last_name, people.suffix, people.classes, people.medical_notes, people.can_pick_up, people.cannot_pick_up'
    if params[:family_barcode_id]
      @people = Person.all(:joins => :family, :conditions => ["(families.barcode_id = ? or families.alternate_barcode_id = ?) and people.deleted = ?", params[:family_barcode_id], params[:family_barcode_id], false], :select => select)
    elsif params[:q]
      search = Search.new_from_params(:family_name => params[:q])
      if (families = search.query(nil, 'family')).any?
        @people = Person.all(:joins => :family, :conditions => ["families.id in (#{families.map(&:id).join(',')}) and people.deleted = ?", false], :select => select)
      else
        @people = []
      end
    else
      render :text => 'missing param', :status => 400
    end
    @people += Relationship.all(:conditions => "related_id in (#{@people.map { |p| p.id }.join(',')}) and other_name like '%Check-in Person%'").map { |r| r.person }.uniq if @people.any?
    respond_to do |format|
      format.json do
        json = {
          'people' => @people.map do |person|
            person.attributes.merge({
              :family_id          => person.family_id,
              :family_barcode_id  => params[:family_barcode_id],
              :attendance_records => person.attendance_today.inject({}) do |records, record|
                records[record.attended_at.to_s(:time)] = [record.group_id, record.group.name]
                records
              end
            })
          end,
          'meta' => {
            'groups_updated_at' => GroupTime.last(:order => 'updated_at').updated_at
          }
        }.to_json
        render :text => json
      end
    end
  end
  
end
