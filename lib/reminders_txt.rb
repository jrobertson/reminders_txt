#!/usr/bin/env ruby

# file: reminders_txt.rb


require 'dynarex'
require 'event_nlp'
require 'digest/md5'


class RemindersTxt

  
  attr_reader :reminders, :dx
  
  def initialize(raw_s='reminders.txt', now: Time.now)

    super()

    @now = now    

    
    @filepath = raw_s
    
    if raw_s.lines.length > 1 then

      if raw_s.lstrip[0] == '<' then

        @filepath = 'reminders.xml'
        @dx = Dynarex.new raw_s
        
      else

        @filepath = File.join(Dir.pwd, 'reminders.txt')
        @dxfilepath = @filepath.sub(/.txt$/,'.xml')              

        @dx = Dynarex.new
        import_txt(raw_s)       
        
      end
      
    elsif File.extname(@filepath) == '.txt'

      s = File.read @filepath
      @filename =  File.basename(@filepath)
      @dxfilepath = @filepath.sub(/.txt$/,'.xml')      
      
      import_txt(s)
      
    else
      
      @dx = Dynarex.new @filepath
      
    end
  end
  
  def add(s)

    s.strip!
    r = EventNlp.new(@now, params: {input: s}).parse(s)
    return if r.nil?
    
    @reminders << r
    refresh()        

  end

  def upcoming(ndays=5, days: ndays)
    @dx.filter {|x| DateTime.parse(x.date) <= @now.to_datetime + days.to_i}
  end
    
  def updated?()
    @updated
  end  
  
  def to_s()

    filename = File.basename(@filepath).sub(/\.xml$/, '.txt')
    [filename,  '=' * filename.length, '', *@dx.all.map(&:input)].join("\n")

  end
  
  def to_xml()
    @dx.to_xml pretty: true
  end   
  
  private
  
  def import_txt(s)

    @file_contents = s
    buffer = s.lines[2..-1]

    @reminders = buffer.inject([]) do |r, x|
      
      x.strip!

      if (x.length > 1) then

        rx = EventNlp.new(@now, params: {input: x}).parse(x)
        r << rx if rx
      end

      r
    end
    
    @updated = false

    refresh()
    
  end
  
  # synchronise with the XML file and remove any expired dates
  #
  def refresh()

    reminders = @reminders.clone
    # if XML file doesn't exist, create it

    if File.exists? @dxfilepath then

      @dx = Dynarex.new @dxfilepath

      @reminders.each do |reminder|
        s = reminder.input
        r = @dx.find_by_input s
        
        # it is on file and it's not an annual event?
        # use the date from file if the record exists
        
        reminder.date = (r and not s[/\*$/]) ? DateTime.parse(r.date) : \
                                                    reminder.date.to_datetime
        
      end
      
    else

      save_dx()
            
    end

    # delete expired non-recurring reminders
    @reminders.reject! {|x| x.date.to_time < @now if not x.recurring }
    
    @reminders.sort_by!(&:date)

    # did the reminders change?
    
    h1 = (Digest::MD5.new << self.to_s).to_s
    h2 = (Digest::MD5.new << @file_contents).to_s

    b = h1 != h2

    if b or @reminders != reminders then
      
      save_dx()      
      File.write File.join(File.dirname(@filepath), 'reminders.txt'), self.to_s 
      @updated = true
    end
    
    [:refresh, b]
        
  end  
  
  def save_dx()
    
    @dx = Dynarex.new(
      'reminders/reminder(input, title, recurring, date, end_date)')
    @reminders.each {|x| @dx.create x.to_h}
    @dx.save @dxfilepath
    
  end
  
  
end