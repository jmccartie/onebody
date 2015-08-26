require_relative '../rails_helper'

describe ImportExecution do
  let(:import) do
    FactoryGirl.create(
      :import,
      status: 'previewed',
      match_strategy: 'by_id_only',
      mappings: {
        'id'        => 'id',
        'first'     => 'first_name',
        'last'      => 'last_name',
        'fam_id'    => 'family_id',
        'fam_name'  => 'family_name',
        'fam_lname' => 'family_last_name',
        'phone'     => 'family_home_phone',
        'email'     => 'email'
      }
    )
  end

  subject { ImportExecution.new(import) }

  def create_row(attrs)
    FactoryGirl.create(
      :import_row,
      import: import,
      import_attributes_attributes: attrs.each_with_index.map do |(name, value), index|
        { import: import, name: name.to_s, value: value, sequence: index }
      end
    )
  end

  describe '#execute' do
    it 'updates the import status' do
      expect { subject.execute }.to change(import, :status).from('previewed').to('complete')
    end

    context 'given dangerous attribute mappings' do
      let(:import) do
        FactoryGirl.create(
          :import,
          status: 'previewed',
          match_strategy: 'by_id_only',
          mappings: {
            'id'       => 'id',
            'first'    => 'first_name',
            'site_id'  => 'site_id',
            'password' => 'encrypted_password',
            'consent'  => 'parental_consent'
          }
        )
      end

      let!(:person) { FactoryGirl.create(:person) }
      let!(:row) { create_row(id: person.id, first: 'Changed', site_id: '100', password: 'pwnd', consent: 'pwnd') }

      it 'does not update anything dangerous' do
        expect {
          subject.execute
        }.not_to change {
          person.reload.attributes.reject { |k| !%w(site_id encrypted_password parental_consent).include?(k) }
        }
        expect(row.reload.updated_person).to eq(true)
        expect(person.reload.first_name).to eq('Changed')
      end
    end

    context 'given the match strategy is by_id_only' do
      before do
        import.match_strategy = :by_id_only
        import.save!
      end

      context 'given a row with an existing person id and existing family id' do
        let(:family)  { FactoryGirl.create(:family) }
        let!(:person) { FactoryGirl.create(:person) }

        context 'given the attributes are valid' do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: family.id) }

          before { subject.execute }

          it 'updates the person but not the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'records how the records were matched' do
            expect(row.reload.matched_person_by_id?).to eq(true)
            expect(row.matched_family_by_id?).to eq(true)
          end
        end

        context 'given the person attributes are invalid' do
          let!(:row) { create_row(id: person.id, first: '', last: 'Jones', fam_id: family.id) }

          before { subject.execute }

          it 'does not update and records the erorr message' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false,
              'error_reasons'  => 'The person must have a first name.'
            )
          end
        end

        context 'given the family attributes are invalid' do
          let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: family.id, fam_name: '') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false,
              'error_reasons'  => 'The family must have a name.'
            )
          end
        end
      end

      context 'given a row with an existing person id and new family id' do
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family) { person.family }

        let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_id: 'new123', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and creates the family' do
          expect(person.reload.family).not_to eq(family)
          expect(person.family.reload.name).to eq('John Jones')
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => true,
            'updated_person' => true,
            'updated_family' => false
          )
        end
      end

      context 'given a row with an existing person id and no family id' do
        let!(:person) { FactoryGirl.create(:person) }
        let!(:family) { person.family }

        let!(:row) { create_row(id: person.id, first: 'John', last: 'Jones', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and updates the family' do
          expect(person.reload.family).to eq(family)
          expect(person.family.reload.name).to eq('John Jones')
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => true,
            'updated_family' => true
          )
        end
      end

      context 'given a new row with a blank family id' do
        let!(:row) { create_row(first: 'John', last: 'Jones', fam_id: '', fam_name: 'John Jones') }

        before { subject.execute }

        it 'creates the person and the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given 2 new rows with the same new family id' do
        let!(:row1) { create_row(first: 'John', last: 'Jones', fam_id: '100', fam_name: 'John & Jane Jones') }
        let!(:row2) { create_row(first: 'Jane', last: 'Jones', fam_id: '100', fam_name: 'John & Jane Jones') }

        before { subject.execute }

        it 'creates the first person and family' do
          expect(row1.reload.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the second person but not the family' do
          expect(row2.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row with an existing family id' do
        let(:family) { FactoryGirl.create(:family) }
        let!(:row)   { create_row(first: 'John', last: 'Jones', fam_id: family.id) }

        before { subject.execute }

        it 'creates the person but not the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end
    end

    context 'given the match strategy is by_name' do
      before do
        import.match_strategy = :by_name
        import.save!
      end

      context 'given a row with an existing person name and existing family name' do
        let(:family) { FactoryGirl.create(:family, name: 'John Jones') }
        let(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones', family: family) }

        context 'given the attributes are valid and the data is unchanged' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_name: family.name) }

          before { subject.execute }

          it 'does not update the person or the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end

          it 'records how the records were matched' do
            expect(row.reload.matched_person_by_name?).to eq(true)
            expect(row.matched_family_by_name?).to eq(true)
          end
        end

        context 'given the attributes are valid and the person changed' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, email: 'new@a.com', fam_name: family.name) }

          before { subject.execute }

          it 'updates the person but not the family' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => true,
              'updated_family' => false
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end

        context 'given the person attributes are invalid' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, email: 'bad', fam_name: family.name, fam_lname: 'Changed') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false,
              'error_reasons'  => 'The email address is not formatted correctly (something@example.com).'
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end

        context 'given the family attributes are invalid' do
          let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_name: family.name, fam_lname: '') }

          before { subject.execute }

          it 'does not update and records the error message' do
            expect(row.reload.attributes).to include(
              'created_person' => false,
              'created_family' => false,
              'updated_person' => false,
              'updated_family' => false,
              'error_reasons'  => 'The family must have a last name.'
            )
          end

          it 'records the matched person and family' do
            expect(row.reload.person).to eq(person)
            expect(row.family).to eq(family)
          end
        end
      end

      context 'given a row with an existing person name and new family name and family id present' do
        let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones') }

        let!(:row) { create_row(first: person.first_name, last: person.last_name, fam_id: 'new', fam_name: 'John Jones') }

        before { subject.execute }

        it 'updates the person and creates the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => true,
            'updated_person' => true,
            'updated_family' => false
          )
        end

        it 'records the matched person and the new family' do
          expect(row.reload.person).to eq(person)
          expect(row.family.attributes).to include(
            'name' => 'John Jones'
          )
        end
      end

      context 'given a new row with invalid person attributes and new family name' do
        let!(:row) { create_row(first: 'John', last: '', fam_name: 'John Jones') }

        before { subject.execute }

        it 'does not update the person or family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given 3 new rows with 2 of them having the same family name' do
        let!(:row1) { create_row(first: 'Bob',  last: 'Jones', fam_name: 'Bob Jones') }
        let!(:row2) { create_row(first: 'John', last: 'Jones', fam_name: 'John & Jane Jones') }
        let!(:row3) { create_row(first: 'Jane', last: 'Jones', fam_name: 'John & Jane Jones') }

        before { subject.execute }

        it 'creates the first person and family' do
          expect(row1.reload.person.attributes).to include(
            'first_name' => 'Bob',
            'last_name'  => 'Jones'
          )
          expect(row1.person.family.attributes).to include(
            'name' => 'Bob Jones'
          )
          expect(row1.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the second person and family' do
          expect(row2.reload.person.attributes).to include(
            'first_name' => 'John',
            'last_name'  => 'Jones'
          )
          expect(row2.person.family.attributes).to include(
            'name' => 'John & Jane Jones'
          )
          expect(row2.attributes).to include(
            'created_person' => true,
            'created_family' => true,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'creates the third person but not the family' do
          expect(row3.reload.person.attributes).to include(
            'first_name' => 'Jane',
            'last_name'  => 'Jones'
          )
          expect(row3.person.family.attributes).to include(
            'name' => 'John & Jane Jones'
          )
          expect(row3.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row with an existing family id' do
        let(:family) { FactoryGirl.create(:family) }
        let!(:row)   { create_row(first: 'John', last: 'Jones', fam_name: family.name) }

        before { subject.execute }

        it 'creates the person but not the family' do
          expect(row.reload.attributes).to include(
            'created_person' => true,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end
      end

      context 'given a new row with a blank family name' do
        let!(:row) { create_row(first: 'John', last: 'Jones', fam_name: '') }

        before { subject.execute }

        it 'does not create the person or the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => false,
            'updated_family' => false
          )
        end

        it 'saves the error message' do
          expect(row.reload.error_reasons).to match(/must have a name/)
        end
      end

      context 'given a row with an blank id' do
        let!(:family) { FactoryGirl.create(:family, name: 'John Jones') }
        let!(:person) { FactoryGirl.create(:person, first_name: 'John', last_name: 'Jones', family: family) }

        let!(:row) { create_row(id: '', first: person.first_name, last: person.last_name, email: 'a@new.com', fam_id: '', fam_name: family.name, fam_lname: 'Changed') }

        before { subject.execute }

        it 'updates the person and the family' do
          expect(row.reload.attributes).to include(
            'created_person' => false,
            'created_family' => false,
            'updated_person' => true,
            'updated_family' => true,
            'error_reasons'  => nil
          )
        end

        it 'records the matched person and familiy' do
          expect(row.reload.person).to eq(person)
          expect(row.family).to eq(family)
        end
      end
    end
  end
end
