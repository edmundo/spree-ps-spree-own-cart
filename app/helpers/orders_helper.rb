module OrdersHelper  
  def to_iso(text)
    Iconv.iconv('iso-8859-1', 'utf-8', text).to_s
  end

  def to_utf(text)
    Iconv.iconv('utf-8', 'iso-8859-1', text).to_s
  end
end