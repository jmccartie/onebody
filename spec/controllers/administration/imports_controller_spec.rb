require_relative '../../rails_helper'

describe Administration::ImportsController, type: :controller do
  let(:admin) { FactoryGirl.create(:person, :admin_import_data) }

  describe '#index' do
    let!(:import) { FactoryGirl.create(:import, person: admin) }

    before do
      get :index, {}, logged_in_id: admin.id
    end

    it 'renders the index template' do
      expect(response).to render_template(:index)
    end
  end

  describe '#show' do
    let(:import) { FactoryGirl.create(:import, person: admin) }

    before do
      get :show, { id: import.id }, logged_in_id: admin.id
    end

    it 'renders the show template' do
      expect(response).to render_template(:show)
    end
  end

  describe '#new' do
    before do
      get :new, {}, logged_in_id: admin.id
    end

    it 'renders the new template' do
      expect(response.status).to eq(200)
      expect(response).to render_template(:new)
    end
  end

  describe '#create' do
    let(:file) { fixture_file_upload('files/people.csv', 'text/csv') }

    before do
      allow_any_instance_of(Import).to receive(:parse_async)
      post :create, { file: file }, logged_in_id: admin.id
    end

    it 'creates a new Import and redirects to it' do
      import = assigns[:import]
      expect(response).to redirect_to(
        edit_administration_import_path(import)
      )
    end

    it 'assigns a filename to the new import' do
      expect(assigns[:import].filename).to eq('people.csv')
    end
  end

  describe '#edit' do
    let(:import) { FactoryGirl.create(:import, person: admin) }

    context 'import is pending' do
      before do
        get :edit, { id: import.id }, logged_in_id: admin.id
      end

      it 'renders the parsing template' do
        expect(response).to render_template(:parsing)
      end
    end

    context 'import is parsed' do
      before do
        import.update_attribute(:status, :parsed)
        get :edit, { id: import.id }, logged_in_id: admin.id
      end

      it 'renders the edit template' do
        expect(response).to render_template(:edit)
      end
    end
  end

  describe '#update' do
    let(:import) { FactoryGirl.create(:import, person: admin) }

    before do
      patch :update, {
        id: import.id,
        import: {
          match_strategy: 'by_name',
          mappings: {
            'foo' => 'bar'
          }
        }
      }, logged_in_id: admin.id
    end

    it 'updates the import settings and redirects to the show page' do
      expect(import.reload.match_strategy).to eq('by_name')
      expect(import.mappings).to eq(
        'foo' => 'bar'
      )
      expect(response).to redirect_to(administration_import_path(import))
    end
  end

  describe '#destroy' do
    let(:import) { FactoryGirl.create(:import, person: admin) }

    before do
      delete :destroy, { id: import.id }, logged_in_id: admin.id
    end

    it 'destroys the import' do
      expect { import.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'redirects to the index' do
      expect(response).to redirect_to(administration_imports_path)
    end
  end
end
