class Visit < ActiveRecord::Base
  belongs_to :spot, :counter_cache => true
  belongs_to :map, :class_name => "TrekMap", :foreign_key => 'trek_map_id'
  has_many :photos, :dependent => :destroy do
    def page_including(photo_id, per_page = 6)
      included = find(photo_id)
      count = count(:conditions => ["position <= ?", included.position])
      (count.to_f / per_page).ceil
    end
  end
  has_many :notes, :dependent => :destroy
  
  after_save :confirm_spot_saved
  after_destroy :destroy_useless_spot
  
  named_scope :to_spot, lambda {|spot| {:conditions => ["spot_id = ?", spot.kind_of?(Spot) ? spot.id : spot]}}
  named_scope :visited_around, lambda {|date| {:conditions => ["visited_on >= ? && visited_on <= ?", date - 3, date + 3]}}
  named_scope :in_year, lambda {|year|
    year = year.to_i
    start_date = Date.new(year, 1, 1)
    end_date = Date.new(year+1, 1, 1)
    {:conditions => ["visited_on >= ? and visited_on < ?", start_date, end_date], :order => "visited_on"}
  }
  named_scope :contains, lambda {|keywords|
    raise "keywords are empty!" if keywords.empty?
    cond_strs = []
    cond_params = []
    for k in keywords
      cond_strs << "spots.name like ? or notes.subject like ? or notes.body like ?"
      for i in 1..3
        cond_params << "%#{k}%"
      end
    end
    {:joins => "inner join spots on spots.id = visits.spot_id left outer join notes on notes.visit_id = visits.id",
     :conditions => [cond_strs.join(' or ')].concat(cond_params),
     :select => "distinct visits.*", :order => "visited_on"}
  }

  @@include_root_in_json = false
    
    
  protected
  def before_save
    self.user_id = map ? map.user_id : nil
  end
  
  private
  
  def destroy_useless_spot
    spot = self.spot
    if (spot && Visit.count("id", :conditions => ["spot_id = ? and id != ?", spot.id, self.id]).to_i == 0)
      spot.destroy
    end
  end
  
  def confirm_spot_saved
    raise "spot is not saved" if spot.new_record?
  end
  
end
