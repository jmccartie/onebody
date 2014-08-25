require_relative '../../../spec_helper'

describe Administration::Checkin::GroupsController do

  before(:all) { Setting.set(:features, :checkin, true) }
  after(:all)  { Setting.set(:features, :checkin, false) }

  context '#create' do
    let(:user)   { FactoryGirl.create(:person, :admin_manage_checkin) }
    let(:time)   { FactoryGirl.create(:checkin_time, :recurring) }
    let(:folder) { FactoryGirl.create(:checkin_folder) }
    let(:group)  { FactoryGirl.create(:group) }

    context 'adding to a folder' do
      before do
        post :create, { ids: [group.id], checkin_folder_id: folder.id, time_id: time.id }, { logged_in_id: user.id }
        @group_time = folder.group_times.first
      end

      it 'creates the group time' do
        expect(@group_time).to be
        expect(@group_time.group).to eq(group)
      end

      it 'sets the group time sequence' do
        expect(@group_time.sequence).to eq(1)
      end

      context 'given an existing group' do
        let(:group2) { FactoryGirl.create(:group) }

        it 'sets the sequence to 2' do
          post :create, { ids: [group2.id], checkin_folder_id: folder.id, time_id: time.id }, { logged_in_id: user.id }
          expect(folder.group_times.where(group_id: group2.id).first.sequence).to eq(2)
        end
      end
    end
  end

end
