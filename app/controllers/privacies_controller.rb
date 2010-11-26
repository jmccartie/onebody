class PrivaciesController < ApplicationController

  cache_sweeper :person_sweeper, :family_sweeper, :only => %w(update)

  def show
    if params[:find] == 'memberships'
      raise 'error' unless Membership.sharing_columns.include?(prop = "share_#{params[:sharing]}")
      @memberships = @logged_in.memberships.all(:conditions => ["#{prop} = ?", true])
    elsif params[:membership_id]
      redirect_to edit_group_membership_privacy_path(params[:group_id], params[:membership_id])
    else
      id = params[:person_id] || @logged_in.id
      redirect_to edit_person_privacy_path(id, params_without_action.merge(:anchor => "p#{id}"))
    end
  end

  def edit
    if params[:group_id]
      @group ||= Group.find(params[:group_id])
      @membership ||= Membership.find(params[:membership_id])
      @person = @membership.person
      if @person.member_of?(@group) and @logged_in.can_edit?(@person)
        all = %w(address home_phone mobile_phone work_phone fax email birthday anniversary)
        @visible_to_everyone = all.select { |a| @person.send("share_#{a}?") }
        @sharable_with_group = all - @visible_to_everyone
        render :action => 'edit_membership'
      else
        render :text => t('not_authorized'), :layout => true, :status => 401
      end
    elsif @person = Person.find(params[:person_id])
      @family = @person.family
      if @logged_in.can_edit?(@family)
        unless @family.visible?
          flash[:warning] = t('privacies.family_hidden', :your => @family == @logged_in.family ? t('your') : t('privacies.this'))
        end
      else
        render :text => t('not_authorized'), :layout => true, :status => 401
      end
    end
  end

  def update
    #elsif params[:agree] or params[:commit] == t('privacies.i_agree')
      #update_consent
    @person = Person.find(params[:person_id])
    @family = @person.family
    people_ids = @family.people.all.map { |p| p.id }
    if @logged_in.can_edit?(@family)
      @family.update_attributes!(params[:family])
      Array(params[:memberships]).each do |membership_id, sharing|
        m = Membership.where(["id = ? and person_id in (?)", membership_id, people_ids]).first
        sharing.each do |attribute, value|
          value = false if m.person.attributes[attribute]
          m.attributes = {attribute => value}
        end
        m.save!
      end
      if @family.visible?
        flash[:notice] = t('privacies.saved')
        flash[:warning] = nil
      else
        flash[:warning] = t('privacies.family_hidden', :your => @family == @logged_in.family ? t('your') : t('privacies.this'))
      end
      redirect_to @person
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  private

  def update_consent
    @person = Person.find(params[:person_id])
    @family = @person.family
    if @logged_in.can_edit?(@family) and @family == @logged_in.family
      if params[:agree] == t('privacies.i_agree') + "."
        if person = @family.people.find(params[:person_id])
          @person.parental_consent = "#{@logged_in.name} (#{@logged_in.id}) at #{Time.now.to_s}"
          @person.save
          flash[:notice] = t('privacies.agreement_saved')
        end
      elsif params[:commit] == t('privacies.i_agree')
        flash[:warning] = t('privacies.you_must_check_agreement_statement')
      end
      redirect_to edit_person_privacy_path(@person, :section => params[:anchor])
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

end
