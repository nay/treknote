# The base stored file class.
class Photo < ActiveRecord::Base
  belongs_to :visit
  belongs_to :user
  acts_as_list :scope => :visit
  after_destroy :update_parent
  after_save :update_parent
  validates_presence_of :name
  before_save :set_user_id

  private
  def update_parent
    visit.save if visit
  end

  def set_user_id
    self.user_id = visit ? visit.user_id : nil
  end
end
