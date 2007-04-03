# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 51) do

  create_table "attachments", :force => true do |t|
    t.column "message_id",   :integer
    t.column "name",         :string
    t.column "file",         :binary
    t.column "content_type", :string,   :limit => 50
    t.column "created_at",   :datetime
    t.column "song_id",      :integer
  end

  create_table "comments", :force => true do |t|
    t.column "verse_id",   :integer
    t.column "person_id",  :integer
    t.column "text",       :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "contacts", :force => true do |t|
    t.column "person_id",  :integer
    t.column "owner_id",   :integer
    t.column "updated_at", :datetime
  end

  create_table "events", :force => true do |t|
    t.column "person_id",   :integer
    t.column "name",        :string
    t.column "description", :text
    t.column "when",        :datetime
    t.column "created_at",  :datetime
    t.column "open",        :boolean,  :default => false
    t.column "admins",      :text
    t.column "updated_at",  :datetime
  end

  create_table "families", :force => true do |t|
    t.column "name",               :string
    t.column "last_name",          :string
    t.column "address1",           :string
    t.column "address2",           :string
    t.column "city",               :string
    t.column "state",              :string,   :limit => 2
    t.column "zip",                :string,   :limit => 10
    t.column "home_phone",         :integer,  :limit => 20
    t.column "email",              :string
    t.column "latitude",           :float
    t.column "longitude",          :float
    t.column "share_address",      :boolean,                :default => true
    t.column "share_mobile_phone", :boolean,                :default => false
    t.column "share_work_phone",   :boolean,                :default => false
    t.column "share_fax",          :boolean,                :default => false
    t.column "share_email",        :boolean,                :default => false
    t.column "share_birthday",     :boolean,                :default => true
    t.column "share_anniversary",  :boolean,                :default => true
    t.column "legacy_id",          :integer
    t.column "mail_group",         :string,   :limit => 1
    t.column "updated_at",         :datetime
    t.column "wall_enabled",       :boolean,                :default => true
    t.column "visible",            :boolean,                :default => true
  end

  create_table "groupmembers", :force => true do |t|
    t.column "group_id",  :integer,                :default => 0,  :null => false
    t.column "member_id", :integer,                :default => 0,  :null => false
    t.column "name",      :string,  :limit => 100, :default => "", :null => false
    t.column "email",     :string,  :limit => 100, :default => "", :null => false
    t.column "nomail",    :integer, :limit => 4,   :default => 0,  :null => false
  end

  create_table "groups", :force => true do |t|
    t.column "name",         :string,   :limit => 100
    t.column "description",  :string,   :limit => 500
    t.column "meets",        :string,   :limit => 100
    t.column "location",     :string,   :limit => 100
    t.column "directions",   :string,   :limit => 500
    t.column "notes",        :string,   :limit => 500
    t.column "creator_id",   :integer
    t.column "address",      :string
    t.column "members_send", :boolean,                 :default => true
    t.column "link_code",    :string,   :limit => 10
    t.column "subscription", :boolean,                 :default => false
    t.column "private",      :boolean,                 :default => false
    t.column "category",     :string,   :limit => 50
    t.column "leader_id",    :integer
    t.column "updated_at",   :datetime
    t.column "archived",     :boolean,                 :default => false
    t.column "approved",     :boolean,                 :default => false
  end

  create_table "groups_legacy", :force => true do |t|
    t.column "name",         :string,  :limit => 100, :default => "", :null => false
    t.column "description",  :string,                 :default => "", :null => false
    t.column "group_type",   :string,  :limit => 50,  :default => "", :null => false
    t.column "meets",        :string,  :limit => 100, :default => "", :null => false
    t.column "location",     :string,  :limit => 100, :default => "", :null => false
    t.column "directions",   :text,                   :default => "", :null => false
    t.column "notes",        :text,                   :default => "", :null => false
    t.column "host_id",      :integer
    t.column "list_address", :string,  :limit => 100, :default => "", :null => false
    t.column "friends",      :text,                   :default => "", :null => false
    t.column "only_friends", :integer, :limit => 4,   :default => 0,  :null => false
    t.column "link_code",    :string,  :limit => 100, :default => "", :null => false
    t.column "deleted",      :integer, :limit => 4,   :default => 0,  :null => false
  end

  add_index "groups_legacy", ["list_address"], :name => "list_address", :unique => true
  add_index "groups_legacy", ["name"], :name => "name"

  create_table "legacy_people", :force => true do |t|
    t.column "family_id",          :integer,                :default => 0,  :null => false
    t.column "sequence",           :integer,                :default => 0,  :null => false
    t.column "gender",             :string,  :limit => 10
    t.column "family_name",        :string,  :limit => 100, :default => "", :null => false
    t.column "family_last_name",   :string,  :limit => 100, :default => "", :null => false
    t.column "first_name",         :string,  :limit => 100, :default => "", :null => false
    t.column "last_name",          :string,  :limit => 100, :default => "", :null => false
    t.column "address1",           :string,  :limit => 100
    t.column "address2",           :string,  :limit => 100
    t.column "city",               :string,  :limit => 50
    t.column "state",              :string,  :limit => 2
    t.column "zip",                :string,  :limit => 10
    t.column "phone",              :string,  :limit => 25
    t.column "mobile_phone",       :string,  :limit => 25
    t.column "birthday",           :date
    t.column "anniversary",        :date
    t.column "family_email",       :string,  :limit => 100
    t.column "email",              :string,  :limit => 100
    t.column "photograph",         :string,  :limit => 50,  :default => "", :null => false
    t.column "classes",            :string,  :limit => 50,  :default => "", :null => false
    t.column "shepherd",           :string,  :limit => 50,  :default => "", :null => false
    t.column "mailgroup",          :string,  :limit => 1,   :default => "", :null => false
    t.column "lat",                :string,  :limit => 25
    t.column "lon",                :string,  :limit => 25
    t.column "remove",             :integer, :limit => 4,   :default => 0,  :null => false
    t.column "nomail",             :integer, :limit => 4,   :default => 0,  :null => false
    t.column "encrypted_password", :string,  :limit => 100
  end

  add_index "legacy_people", ["family_id"], :name => "family_id"
  add_index "legacy_people", ["first_name"], :name => "first_name"
  add_index "legacy_people", ["last_name"], :name => "last_name"
  add_index "legacy_people", ["family_last_name"], :name => "family_last_name"

  create_table "log_items", :force => true do |t|
    t.column "model_name",  :string,   :limit => 50
    t.column "instance_id", :integer
    t.column "changes",     :text
    t.column "person_id",   :integer
    t.column "created_at",  :datetime
    t.column "reviewed_on", :datetime
    t.column "reviewed_by", :integer
    t.column "flagged_on",  :datetime
    t.column "flagged_by",  :integer
  end

  create_table "memberships", :force => true do |t|
    t.column "group_id",           :integer
    t.column "person_id",          :integer
    t.column "admin",              :boolean,  :default => false
    t.column "share_address",      :boolean
    t.column "share_mobile_phone", :boolean
    t.column "share_work_phone",   :boolean
    t.column "share_fax",          :boolean
    t.column "share_email",        :boolean
    t.column "share_birthday",     :boolean
    t.column "share_anniversary",  :boolean
    t.column "get_email",          :boolean,  :default => true
    t.column "updated_at",         :datetime
    t.column "code",               :integer
  end

  create_table "messages", :force => true do |t|
    t.column "group_id",     :integer
    t.column "person_id",    :integer
    t.column "created_at",   :datetime
    t.column "updated_at",   :datetime
    t.column "parent_id",    :integer
    t.column "subject",      :string
    t.column "body",         :text
    t.column "share_email",  :boolean,  :default => false
    t.column "wall_id",      :integer
    t.column "to_person_id", :integer
  end

  create_table "ministries", :force => true do |t|
    t.column "admin_id",    :integer
    t.column "name",        :string,   :limit => 100
    t.column "description", :text
    t.column "updated_at",  :datetime
  end

  create_table "people", :force => true do |t|
    t.column "family_id",           :integer
    t.column "sequence",            :integer
    t.column "gender",              :string,   :limit => 6
    t.column "first_name",          :string
    t.column "last_name",           :string
    t.column "mobile_phone",        :integer,  :limit => 20
    t.column "work_phone",          :integer,  :limit => 20
    t.column "fax",                 :integer,  :limit => 20
    t.column "birthday",            :datetime
    t.column "email",               :string
    t.column "website",             :string
    t.column "classes",             :string
    t.column "shepherd",            :string
    t.column "mail_group",          :string,   :limit => 1
    t.column "encrypted_password",  :string,   :limit => 100
    t.column "activities",          :text
    t.column "interests",           :text
    t.column "music",               :text
    t.column "tv_shows",            :text
    t.column "movies",              :text
    t.column "books",               :text
    t.column "quotes",              :text
    t.column "about",               :text
    t.column "testimony",           :text
    t.column "share_mobile_phone",  :boolean
    t.column "share_work_phone",    :boolean
    t.column "share_fax",           :boolean
    t.column "share_email",         :boolean
    t.column "share_birthday",      :boolean
    t.column "service_name",        :string,   :limit => 100
    t.column "service_description", :text
    t.column "service_phone",       :integer,  :limit => 20
    t.column "service_email",       :string
    t.column "service_website",     :string
    t.column "legacy_id",           :integer
    t.column "email_changed",       :boolean,                 :default => false
    t.column "suffix",              :string,   :limit => 25
    t.column "anniversary",         :datetime
    t.column "updated_at",          :datetime
    t.column "alternate_email",     :string
    t.column "email_bounces",       :integer,                 :default => 0
    t.column "service_category",    :string,   :limit => 100
    t.column "get_wall_email",      :boolean,                 :default => true
    t.column "frozen",              :boolean,                 :default => false
    t.column "wall_enabled",        :boolean
    t.column "messages_enabled",    :boolean,                 :default => true
    t.column "service_address",     :string
    t.column "flags",               :string
    t.column "music_access",        :boolean,                 :default => false
    t.column "visible",             :boolean,                 :default => true
    t.column "parental_consent",    :string
  end

  create_table "people_verses", :id => false, :force => true do |t|
    t.column "person_id", :integer
    t.column "verse_id",  :integer
  end

  create_table "performances", :force => true do |t|
    t.column "setlist_id", :integer
    t.column "song_id",    :integer
    t.column "ordering",   :integer
  end

  create_table "pictures", :force => true do |t|
    t.column "event_id",   :integer
    t.column "person_id",  :integer
    t.column "created_at", :datetime
    t.column "cover",      :boolean,  :default => false, :null => false
    t.column "updated_at", :datetime
  end

  create_table "prayer_signups", :force => true do |t|
    t.column "person_id",  :integer
    t.column "start",      :datetime
    t.column "created_at", :datetime
    t.column "reminded",   :boolean,                 :default => false
    t.column "other",      :string,   :limit => 100
  end

  create_table "publications", :force => true do |t|
    t.column "name",        :string
    t.column "description", :text
    t.column "created_at",  :datetime
    t.column "file",        :string
    t.column "updated_at",  :datetime
  end

  create_table "recipes", :force => true do |t|
    t.column "person_id",    :integer
    t.column "title",        :string
    t.column "notes",        :text
    t.column "description",  :text
    t.column "ingredients",  :text
    t.column "directions",   :text
    t.column "created_at",   :datetime
    t.column "updated_at",   :datetime
    t.column "prep",         :string
    t.column "bake",         :string
    t.column "serving_size", :integer
  end

  create_table "recipes_tags", :id => false, :force => true do |t|
    t.column "tag_id",    :integer
    t.column "recipe_id", :integer
  end

  create_table "sessions", :force => true do |t|
    t.column "session_id", :string
    t.column "data",       :text
    t.column "updated_at", :datetime
  end

  add_index "sessions", ["session_id"], :name => "sessions_session_id_index"

  create_table "setlists", :force => true do |t|
    t.column "start",      :datetime
    t.column "person_id",  :integer
    t.column "created_at", :datetime
  end

  create_table "songs", :force => true do |t|
    t.column "title",            :string
    t.column "notes",            :text
    t.column "artists",          :string,   :limit => 500
    t.column "album",            :string
    t.column "image_small_url",  :string
    t.column "image_medium_url", :string
    t.column "image_large_url",  :string
    t.column "amazon_asin",      :string,   :limit => 50
    t.column "amazon_url",       :string
    t.column "created_at",       :datetime
    t.column "person_id",        :integer
  end

  create_table "songs_tags", :id => false, :force => true do |t|
    t.column "song_id", :integer
    t.column "tag_id",  :integer
  end

  create_table "tags", :force => true do |t|
    t.column "name",       :string,   :limit => 50
    t.column "updated_at", :datetime
  end

  create_table "tags_verses", :id => false, :force => true do |t|
    t.column "tag_id",   :integer
    t.column "verse_id", :integer
  end

  create_table "updates", :force => true do |t|
    t.column "person_id",    :integer
    t.column "first_name",   :string
    t.column "last_name",    :string
    t.column "home_phone",   :integer,  :limit => 20
    t.column "mobile_phone", :integer,  :limit => 20
    t.column "work_phone",   :integer,  :limit => 20
    t.column "fax",          :integer,  :limit => 20
    t.column "address1",     :string
    t.column "address2",     :string
    t.column "city",         :string
    t.column "state",        :string,   :limit => 2
    t.column "zip",          :string,   :limit => 10
    t.column "birthday",     :datetime
    t.column "anniversary",  :datetime
    t.column "created_at",   :datetime
    t.column "complete",     :boolean,                :default => false
  end

  create_table "verifications", :force => true do |t|
    t.column "verified",     :boolean
    t.column "created_at",   :datetime
    t.column "email",        :string
    t.column "code",         :integer
    t.column "mobile_phone", :integer,  :limit => 20
    t.column "updated_at",   :datetime
  end

  create_table "verses", :force => true do |t|
    t.column "reference",   :string,   :limit => 50
    t.column "text",        :text
    t.column "translation", :string,   :limit => 10
    t.column "created_at",  :datetime
    t.column "updated_at",  :datetime
    t.column "book",        :integer
    t.column "chapter",     :integer
    t.column "verse",       :integer
  end

  create_table "workers", :force => true do |t|
    t.column "ministry_id", :integer
    t.column "person_id",   :integer
    t.column "start",       :datetime
    t.column "end",         :datetime
    t.column "remind_on",   :datetime
    t.column "reminded",    :boolean,  :default => false
  end

end
