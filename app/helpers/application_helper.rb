# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  WEEKDAY_NAMES = ['日', '月', '火', '水', '木', '金', '土']
  def format_year(date)
    date.strftime("%Y年")
  end
  def format_date_without_year(date)
    date.strftime("%m/%d")
  end
  def format_date_detailed(date)
    date.strftime("%Y年 %m/%d（#{WEEKDAY_NAMES[date.wday]}）")
  end
  
  def visit_short_name(visit, insert_br = false)
    "#{h visit.spot.name}#{'<br />' if insert_br}（#{visit.visited_on.strftime('%Y/%m/%d')}）"
  end
  
  def visit_formal_name(visit)
    "#{h visit.spot.name} - #{format_date_detailed(visit.visited_on)}"
  end
  
  def format_date(date)
    return '' unless date
    date.strftime("%Y/%m/%d")
  end

  def format_datetime(date)
    return '' unless date
    date.strftime("%Y/%m/%d %H:%M")
  end

  def note_subject_or_default(note)
    return note.subject unless note.subject.blank?
    "#{h note.visit.spot.name}<br />（#{note.visit.visited_on.strftime('%Y/%m/%d')}）"
  end

end
