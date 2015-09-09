require 'tempfile'
require 'stringio'

class Document < ActiveRecord::Base
  include Authority::Abilities
  self.authorizer_name = 'DocumentAuthorizer'

  include Concerns::FileImage

  belongs_to :folder, class_name: 'DocumentFolder', foreign_key: :folder_id, touch: true

  scope :top, -> { where(folder_id: nil) }

  scope_by_site_id

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }
  validates :file, presence: true

  has_attached_file :file, PAPERCLIP_FILE_OPTIONS
  do_not_validate_attachment_file_type :file

  has_attached_file :preview, PAPERCLIP_PHOTO_OPTIONS.merge(
    styles: {
      tn:       '70x70#',
      small:    '150x150>',
      medium:   '500x500>'
    }
  )
  validates_attachment_size :preview, less_than: PAPERCLIP_PHOTO_MAX_SIZE
  validates_attachment_content_type :preview, content_type: PAPERCLIP_PHOTO_CONTENT_TYPES

  validates_attachment_size :file, less_than: PAPERCLIP_FILE_MAX_SIZE

  attr_accessor :dont_preview

  after_commit :build_preview, on: :create, if: :previewable?

  PREVIEWABLE_CONTENT_TYPES = %w(
    application/pdf
  )

  def previewable?
    PREVIEWABLE_CONTENT_TYPES.include?(file_content_type) && !dont_preview
  end

  def build_preview
    # convert -thumbnail x350 test.pdf[0] test.png
    temp = Tempfile.new('preview')
    temp.close
    out_path = temp.path + '.png'
    MiniMagick::Tool::Convert.new do |convert|
      convert << file.path + '[0]'
      convert << out_path
    end
    self.preview = Rack::Test::UploadedFile.new(out_path, 'image/png', true)
    self.dont_preview = true
    save!
  end

  def parent_folders
    return [] if folder.nil?
    [folder] + folder.parent_folders
  end

  def parent_folder_group_ids
    parent_folders.flat_map(&:group_ids).uniq
  end

  def parent_folder_groups
    Group.where(id: parent_folder_group_ids)
  end

  def restricted?
    parent_folder_group_ids.any?
  end

  def hidden?
    parent_folders.any?(&:hidden?)
  end
end
