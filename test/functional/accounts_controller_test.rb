require_relative '../test_helper'

class AccountsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
  end

  context '#show' do
    context 'given a person_id param' do
      setup do
        get :show, {person_id: @person.id}, {logged_in_id: @person.id}
      end

      should 'redirect to the person account path' do
        assert_redirected_to person_account_path(@person)
      end
    end

    context 'given no params' do
      setup do
        get :show, {}, {logged_in_id: @person.id}
      end

      should 'redirect to the new account path' do
        assert_redirected_to new_account_path
      end
    end
  end

  context '#edit' do
    context 'user is account owner' do
      setup do
        get :edit, {person_id: @person.id}, {logged_in_id: @person.id}
      end

      should 'render the edit form' do
        assert_template :edit
      end
    end

    context 'user is not account owner' do
      setup do
        @stranger = FactoryGirl.create(:person)
        get :edit, {person_id: @person.id}, {logged_in_id: @stranger.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      setup do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        get :edit, {person_id: @person.id}, {logged_in_id: @admin.id}
      end

      should 'render the edit form' do
        assert_template :edit
      end
    end
  end

  context '#update' do
    context 'user is account owner' do
      setup do
        @password_was = @person.encrypted_password
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @person.id}
      end

      should 'redirect to the profile page' do
        assert_redirected_to person_path(@person)
      end

      should 'update email address' do
        assert_equal 'foo@example.com', @person.reload.email
      end

      should 'update password' do
        assert_not_equal @password_was, @person.reload.encrypted_password
      end

      context 'bad email given' do
        setup do
          post :update, {person_id: @person.id, person: {email: 'bad', password: 'password', password_confirmation: 'mismatched'}}, {logged_in_id: @person.id}
        end

        should 'be success' do
          assert_response :success
        end

        should 'render edit template again' do
          assert_template :edit
        end
      end

      context 'passwords do not match' do
        setup do
          post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'mismatched'}}, {logged_in_id: @person.id}
        end

        should 'be success' do
          assert_response :success
        end

        should 'render edit template again' do
          assert_template :edit
        end
      end
    end

    context 'user is not account owner' do
      setup do
        @stranger = FactoryGirl.create(:person)
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @stranger.id}
      end

      should 'return forbidden' do
        assert_response :forbidden
      end
    end

    context 'user is an admin with edit_profiles privilege' do
      setup do
        @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true))
        post :update, {person_id: @person.id, person: {email: 'foo@example.com', password: 'password', password_confirmation: 'password'}}, {logged_in_id: @admin.id}
      end

      should 'redirect' do
        assert_response :redirect
      end
    end
  end

  context '#select' do
    context 'GET with select people in session' do
      setup do
        @spouse = FactoryGirl.create(:person, family: @person.family)
        get :select, {}, {select_from_people: [@person, @spouse]}
      end

      should 'render select template' do
        assert_template :select
      end
    end

    context 'POST with select people in session' do
      context 'with a matching id' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, {id: @spouse.id}, {select_from_people: [@person, @spouse]}
        end

        should 'redirect to edit person account path' do
          assert_redirected_to edit_person_account_path(@spouse)
        end

        should 'set flash to warn about setting password' do
          assert_match /set.*email.*password/, flash[:warning]
        end

        should 'clear session select people' do
          assert_nil session[:select_from_people]
        end
      end

      context 'without a matching id' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family)
          post :select, {id: '0'}, {select_from_people: [@person, @spouse]}
        end

        should 'return 200 OK status' do
          assert_response :success
        end

        should 'render select template again' do
          assert_template :select
        end

        should 'clear not session select people' do
          assert_equal [@person, @spouse], session[:select_from_people]
        end
      end
    end

    context 'GET with no select people in session' do
      setup do
        get :select, {}, {}
      end

      should 'return status 410 Gone' do
        assert_response :gone
      end

      should 'return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end

    context 'POST with no select people in session' do
      setup do
        post :select, {id: @person.id}, {}
      end

      should 'return status 410 Gone' do
        assert_response :gone
      end

      should 'return page no longer valid' do
        assert_select 'body', /no longer valid/
      end
    end
  end

  context '#verify_code' do
    context 'given a non-pending email verification' do
      setup do
        @verification = Verification.create!(email: @person.email, verified: false)
        get :verify_code, {id: @verification.id}
      end

      should 'return 404 Not Found' do
        assert_response :not_found
      end
    end

    context 'given a pending email verification' do
      setup do
        @verification = Verification.create!(email: @person.email)
      end

      context 'GET with proper id and code' do
        setup do
          get :verify_code, {id: @verification.id, code: @verification.code}
        end

        should 'mark the verification verified' do
          assert_equal true, @verification.reload.verified?
        end

        should 'redirect to edit person account' do
          assert_redirected_to edit_person_account_path(@person)
        end

        should 'set flash notice to set email' do
          assert_equal I18n.t('accounts.set_your_email_may_be_different'), flash[:warning]
        end

        should 'set logged in user in session' do
          assert_equal @person.id, session[:logged_in_id]
        end
      end

      context 'GET with improper id' do
        should 'raise RecordNotFound exception' do
          assert_raise ActiveRecord::RecordNotFound do
            get :verify_code, {id: '111111111'}
          end
        end
      end

      context 'GET with proper id and wrong code' do
        setup do
          get :verify_code, {id: @verification.id, code: '1'}
        end

        should 'not mark the verification verified' do
          assert_equal false, @verification.reload.verified?
        end

        should 'return 400 Bad Request' do
          assert_response :bad_request
        end

        should 'render text' do
          assert_select 'body', /wrong code/
        end
      end

      context 'matching more than one family member' do
        setup do
          @spouse = FactoryGirl.create(:person, family: @person.family, email: @person.email)
        end

        context 'GET with proper id and code' do
          setup do
            get :verify_code, {id: @verification.id, code: @verification.code}
          end

          should 'mark the verification verified' do
            assert_equal true, @verification.reload.verified?
          end

          should 'set select people in session' do
            assert_equal [@person, @spouse], session[:select_from_people]
          end

          should 'redirect to select account path' do
            assert_redirected_to select_account_path
          end
        end
      end
    end

    context 'given a pending mobile verification' do
      setup do
        @person.update_attribute :mobile_phone, '1234567891'
        @verification = Verification.create!(mobile_phone: @person.mobile_phone)
      end

      context 'GET with proper id and code' do
        setup do
          get :verify_code, {id: @verification.id, code: @verification.code}
        end

        should 'mark the verification verified' do
          assert_equal true, @verification.reload.verified?
        end

        should 'redirect to edit person account' do
          assert_redirected_to edit_person_account_path(@person)
        end

        should 'set flash notice to set email' do
          assert_match /set.*email/, flash[:warning]
        end
      end
    end
  end

  should "create account" do
    Setting.set(1, 'Features', 'Sign Up', true)
    post :create, {person: {email: 'user@example.com'}} # existing user
    assert_response :success
  end

  should "create account with birthday in american date format" do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y')
    post :create, {person: {email:      'bob@example.com',
                               first_name: 'Bob',
                               last_name:  'Morgan',
                               gender:     'Male',
                               birthday:   '01/02/1980'}}
    assert_response :success
    assert bob = Person.find_by_email('bob@example.com')
    assert_equal '01/02/1980', bob.birthday.strftime('%m/%d/%Y')
  end

  should "create account with birthday in european date format" do
    Setting.set(1, 'Features', 'Sign Up', true)
    Setting.set(1, 'Formats', 'Date', '%d/%m/%Y')
    post :create, {person: {email:      'bob@example.com',
                               first_name: 'Bob',
                               last_name:  'Morgan',
                               gender:     'Male',
                               birthday:   '02/01/1980'}}
    assert_response :success
    assert bob = Person.find_by_email('bob@example.com')
    assert_equal 'Jan 02, 1980', bob.birthday.strftime('%b %d, %Y')
  end

end
