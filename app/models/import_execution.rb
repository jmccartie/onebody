class ImportExecution
  include Concerns::Import::Attributes

  def initialize(import)
    @import = import
    @created_family_ids = {}
    @created_family_names = {}
  end

  def execute
    return unless ready?
    @import.update_attributes(status: status_before)
    @import.rows.each do |row|
      row.reset_statuses
      if (person = row.match_person)
        update_existing_person(row, person)
      else
        create_new_person(row)
      end
      save_row(row)
    end
    @import.update_attributes(status: status_after)
  end

  private

  def status_before
    'previewed'
  end

  def status_during
    'active'
  end

  def status_after
    'complete'
  end

  def ready?
    @import.status == status_before
  end

  def save_row(row)
    row.person.save
    row.family.save
    row.save!
  end

  def update_existing_person(row, person)
    person.attributes = attributes_for_person(row)
    if (family = match_family(row))
      person.family = family
      update_existing_family(row, family)
    elsif person.family && id_for_family(row).blank?
      update_existing_family(row, person.family)
    else
      create_new_family(row, person)
    end
    row.updated_person = (person.valid? && person.changed?)
    row.created_family = row.updated_family = false if person.invalid?
    row.error_reasons = errors_as_string(person)
    row.person = person
  end

  def create_new_person(row)
    person = Person.new(attributes_for_person(row))
    if (person.family = match_family(row))
      update_existing_family(row, person.family)
    else
      create_new_family(row, person)
    end
    row.created_person = person.valid?
    row.created_family = row.updated_family = false if person.invalid?
    row.error_reasons = errors_as_string(person)
    row.person = person
  end

  def update_existing_family(row, family)
    attrs_before = family.attributes.dup
    family.attributes = attributes_for_family(row)
    row.updated_family = (family.attributes != attrs_before) && family.valid?
    row.family = family
  end

  def create_new_family(row, person)
    attrs = attributes_for_family(row)
    person.family = Family.new(attrs)
    person.family.last_name ||= person.family.name.split.last if person.family.name.present?
    if (row.created_family = person.family.valid?)
      if (id = id_for_family(row))
        @created_family_ids[id] = person.family
      else
        @created_family_names[attrs['name']] = person.family
      end
    end
    row.family = person.family
  end

  def match_family(row)
    row.match_family ||
      ((id = id_for_family(row)) && @created_family_ids[id]) ||
      ((name = attributes_for_family(row)['name']) && @created_family_names[name])
  end
end
