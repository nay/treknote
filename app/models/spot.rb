class Spot < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :latitude
  validates_presence_of :longitude
  validates_uniqueness_of :name, :scope => [:latitude, :longitude]
  
  @@include_root_in_json = false
  
  def latitude_str
    cut_zero(self.latitude)
  end
  def longitude_str
    cut_zero(self.longitude)
  end
  
  private
  def cut_zero(f)
    s = f.to_s
    while s =~ /\.(.)*0$/
      s = s[0, s.length-1]
    end
    s
  end
  
end
