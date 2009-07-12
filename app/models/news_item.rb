# == Schema Information
#
# Table name: news_items
#
#  id         :integer       not null, primary key
#  title      :string(255)   
#  link       :string(255)   
#  body       :text          
#  created_at :datetime      
#  active     :boolean       default(TRUE)
#  site_id    :integer       
#  source     :string(255)   
#  person_id  :integer       
#

class NewsItem < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  belongs_to :person
  belongs_to :site
  
  scope_by_site_id
  acts_as_logger LogItem
  
  def name; title; end
  
  before_save :update_published_date
  
  def update_published_date
   self.published = Time.now if published.nil?
  end
  
  after_create :create_as_stream_item
  
  def create_as_stream_item
    StreamItem.create!(
      :title           => title,
      :body            => body,
      :person_id       => person_id,
      :streamable_type => 'NewsItem',
      :streamable_id   => id,
      :created_at      => created_at
    )
  end
  
  after_destroy :delete_stream_items
  
  def delete_stream_items
    StreamItem.destroy_all(:streamable_type => 'NewsItem', :streamable_id => id)
  end
  
  class << self
    def update_from_feed
      if raw_items = get_feed_items
        active = []
        raw_items.each do |raw_item|
          item = NewsItem.find_by_link(raw_item.url) || NewsItem.new
          item.link = raw_item.url
          item.title = raw_item.title
          item.body = raw_item.content || raw_item.summary
          item.published = raw_item.published
          item.active = true
          item.source = 'feed'
          item.save
          active << item
        end
        NewsItem.update_all("active = 0", "source = 'feed' and id not in (#{active.map { |n| n.id }.join(',')})") if active.any?
      end
    end  
    
    def get_feed_items
      if url = Setting.get(:url, :news_rss)
        begin
          feed = Feedzirra::Feed.fetch_and_parse(url)
          feed.entries
        rescue
          nil
        end
      end
    end
  end
end
