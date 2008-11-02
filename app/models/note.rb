class Note < ActiveRecord::Base
  belongs_to :visit
  
  before_save :set_user_id
  after_save :update_parent
  after_destroy :update_parent

  named_scope :updated, {:order => "updated_at desc"}

  def subject_or_head
    return self.subject unless subject.blank?
    body =~ /(.{1,20})/
    str = $1
    str += '...' if str != self.body
    str
  end
  
  def body_head(size = 10)
    body =~ /(.{1,#{size}})/
    str = $1
    str += '...' if str != self.body
    str
  end
  
  protected
  def validate
    errors.add_to_base("題か本文を入力してください。") if subject.blank? && body.blank?
  end
  
  private
  def set_user_id
    self.user_id = visit ? visit.user_id : nil
  end
  
  def update_parent
    visit.save! if visit  # updated_at を更新する
  end
end
