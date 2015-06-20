# email.rb

class ParsedEmail

  attr_reader :headers,
              :body
  
  def initialize path
    @path = path
    parse(path)
  end

  #creates headers/body vars for use below
  def parse path
    headers, body = path.read.split("\n\n", 2)
    @headers      = parse_headers(headers)
    @body         = parse_body(self.content_type, body)
  end

  #for view calls
  def subject()      self.headers["Subject"] || "[NO SUBJECT]" end
  def date()         self.headers["Date"] end
  def content_type() self.headers["Content-Type"].split(";").first rescue nil end
  def mime_version() self.headers["MIME-Version"] || self.headers["Mime-Version"] rescue nil end
  
  
  #to/from fields
  def addresses_in field
    self.headers[field].scan(/[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+/).flatten.uniq rescue nil
  end

  def readable_emails header
    addresses_in(header).join(", ") rescue nil
  end

  def from()         readable_emails("From") end
  def to()           readable_emails("To") end
  def cc()           readable_emails("Cc") end
  def bcc()          readable_emails("Bcc") end
  def delivered_to() readable_emails("Delivered-To") end
  def return_path()  readable_emails("Return-Path") end


  #hash of headers
  def parse_headers raw_headers
    headers = Hash.new

    # Store values
    remove_fws(raw_headers).map do |line|
      key, value = line.split(": ", 2)
      headers[key] ||= []
      headers[key] << value unless headers[key].include? value
    end

    # Pop value from array if there's only one value
    headers.each{ |key, value| headers[key] = value.pop if value.length == 1 }
  end


  # Removes FWS from headers, returns an array for each header
  def remove_fws headers_with_fws
    headers = Array.new
    headers_with_fws.each_line do |line|
      next if line =~ /^\s+$/ # If line is empty
      next if line =~ /^((?!:)[\s\S])*$/ && headers.size == 0 # If they're trying to pull a fast one
      line =~ /^\s/ ? headers[-1] += line.strip : headers << line.strip
    end
    headers
  end


  # Returns hash of body, with types as keys
  # No it doesn't, yet
  def parse_body content_type, body
    body.lstrip! rescue nil
    case content_type
    when "multipart/alternative" then parse_multipart_alternative(body)
    when "text/plain"            then parse_text_plain(body)
    when "text/html"             then parse_text_html(body)
    when nil                     then ["[No Content]"]
    else                              [content_type + " not yet supported"]
    end
  end


  # Returns an array of each part of the email
  def parse_multipart_alternative raw_body

    # Use the boundary to split up each part of the email
    boundary = get_boundary(@headers["Content-Type"])
    bodies = raw_body.split(boundary + "\n")[1..-1].map { |body|

      # Lather, rinse, repeat:  get the content and bodies of each part, then parse
      body_content_type = body.split("Content-Type: ", 2).last.split(";", 2).first
      body = body.split(/\n\n/, 2).last.gsub(/#{boundary}--/, "")
      parse_body(body_content_type, body)
    }.flatten
  end


  # Pulls the boundary out of the content-type header, returns as string
  def get_boundary content_type_header
    comments = content_type_header.split(";", 2).last
    boundary = "--" + comments.match(/boundary=(.+)[;]|boundary=(.+)[\w]/).to_s.gsub(/(boundary=)|(")|(;)/, "")
  end

  def parse_text_plain raw_body
    ['<pre>' + raw_body.gsub("=\n","").gsub("=3D", "=") + '</pre>']
  end


  def parse_text_html raw_body
    ['<section class="html">' + raw_body.gsub("=C2=A0"," ").gsub(/(?:\n\r?|\r\n?)|=/,"").gsub("C2A0"," ").gsub("\t", "") + '</section>']
  end


end