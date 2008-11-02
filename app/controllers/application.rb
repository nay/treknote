# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem;
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'b30321f757650e8c8efecd82da3e4c20'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def self.stylesheet(*args)
    unless args.empty?
      write_inheritable_attribute(:custom_stylesheet, args)
    else
      read_inheritable_attribute(:custom_stylesheet)
    end
  end
  
  private
  def visit_short_name(visit, insert_br = false)
    "#{ERB::Util.h visit.spot.name}#{'<br />' if insert_br}（#{visit.visited_on.strftime('%Y/%m/%d')}）"
  end  
  def visit_formal_name(visit)
    "#{ERB::Util.h visit.spot.name} - #{format_date_detailed(visit.visited_on)}"
  end
  def format_date_detailed(date)
    date.strftime("%Y年 %m/%d（#{ApplicationHelper::WEEKDAY_NAMES[date.wday]}）")
  end
  def note_subject_or_default(note)
    return note.subject unless note.subject.blank?
    "#{ERB::Util.h note.visit.spot.name}<br />（#{note.visit.visited_on.strftime('%Y/%m/%d')}）"
  end
end
