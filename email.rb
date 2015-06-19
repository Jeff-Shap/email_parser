# email.rb

class ParsedEmail

  def initialize path
    parse(path)
  end

  def subject
    self.headers["Subject"] || "[NO SUBJECT]" end
  end
  
end