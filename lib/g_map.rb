class GMap
  attr_accessor :lat, :lng, :zoom
    
  def initialize(t, g, z)
    @lat = t
    @lng = g
    @zoom = z
  end
  
  WORLD = GMap.new(34, 150, 1)
  
end