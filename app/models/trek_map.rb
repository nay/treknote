class TrekMap < ActiveRecord::Base
  has_many :visits, :order => "visited_on desc", :dependent => :destroy do
    def last_updated
      find(:first, :order => "updated_at desc")
    end
  end
  has_many :notes, :through => :visits, :order => "updated_at desc"
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => "user_id"
end
