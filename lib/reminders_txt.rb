#!/usr/bin/env ruby

# file: reminders_txt.rb


require 'dynarex'
require 'app-routes'
require 'digest/md5'
require 'chronic_cron'


module Ordinals

  refine Integer do
    def ordinal
      self.to_s + ( (10...20).include?(self) ? 'th' : 
                    %w{ th st nd rd th th th th th th }[self % 10] )
    end
  end
end



class RemindersTxt
  include AppRoutes
  using Ordinals
  
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

  def upcoming(ndays=5, days: ndays)
    @dx.filter {|x| Date.parse(x.date) <= @now.to_date + days.to_i}
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
    
  protected

  def expressions(params) 

    
    # some event every 2 weeks
    # some event every 2 weeks at 6am starting from 14th Jan
    # some event every 2 weeks at 6am starting from 18th Feb until 28th Oct
    # some event every 2nd Monday (starting 7th Nov 2016)
    # some event every 2nd Monday (starting 7th Nov until 3rd Dec)


    starting = /(?:\(?\s*starting (\d+\w{2} \w+\s*\w*)(?: until (.*))?\s*\))?/
    weekday = Date::DAYNAMES.join('|').downcase

    get /^(.*)(every \w+ \w+(?: at (\d+am) )?)\s*#{starting}/ do \
                                   |title, recurring, time, raw_date, end_date|
      
      input = params[:input]
      
      d = Chronic.parse(raw_date)
      
      if recurring =~ /day|week/ then
                
        
        if d < @now then
          
          new_date = CronFormat.new(ChronicCron.new(recurring)\
                                    .to_expression, d).to_time
          input.gsub!(raw_date, new_date\
                      .strftime("#{new_date.day.ordinal} %b %Y"))        
          d = new_date
          
        end
      end
      

      #puts [0, title, recurring, time, raw_date, end_date].inspect
      OpenStruct.new input: input, title: title, recurring: recurring, 
                                                date: d, end_date: end_date
      
    end
    
    # some meeting 3rd thursday of the month at 7:30pm
    # some meeting First thursday of the month at 7:30pm
    get /(.*)\s+(\w+ \w+day of (?:the|every) month at .*)/ do |title, recurring|

      #puts [1, title, recurring].inspect      
      OpenStruct.new input: params[:input], title: title, recurring: recurring

    end
    
    # hall 2 friday at 11am
    get /(.*)\s+(#{weekday})\s+at\s+(.*)/i do |title, raw_day, time|
      
      d = Chronic.parse(raw_day + ' ' + time)
      
      #puts [1.5, title, raw_day].inspect
      OpenStruct.new input: params[:input], title: title, date: d
      
    end
 
    # hall 2 friday at 11am
    # some important day 24th Mar
    get /([^\d]+)\s+(\d+[^\*]+)(\*)?/ do |title, raw_date, annualar|

      d = Chronic.parse(raw_date)
      
      recurring = nil
      
      if annualar then
        
        recurring = 'yearly'
        if d < @now then
          d = Chronic.parse(raw_date, now: Time.local(@now.year + 1, 1, 1)) 
        end
      end
      
      #puts [2, title, raw_date].inspect
      OpenStruct.new input: params[:input], title: title, date: d, 
                                                        recurring: recurring      
    end
    
    # 27-Mar@1436 some important day
    get /(\d[^\s]+)\s+([^\*]+)(\*)?/ do |raw_date, title, annualar|

      d = Chronic.parse(raw_date, :endian_precedence => :little)
      recurring = nil
      
      if annualar then
        
        recurring = 'yearly'
        if d < @now then
          d = Chronic.parse(raw_date, now: Time.local(@now.year + 1, 1, 1)) 
        end
      end
      
      
      #puts [3, title, raw_date].inspect
      OpenStruct.new input: params[:input], title: title, date: d, 
                                                    recurring: recurring      
    end    
    
    # e.g. 04-Aug@12:34
    get '*' do

      'pattern unrecognised'
    end


  end
  
  alias find_expression run_route
  
  private
  
  def import_txt(s)

    @file_contents = s
    @params = {}
    expressions(@params)
    buffer = s.lines[2..-1]

    @reminders = buffer.inject([]) do |r, x|  
      if (x.length > 1) then
        @params[:input] = x.strip
        rx = find_expression(x) 
        r << rx
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
        
        reminder.date = (r and not s[/\*$/]) ? Date.parse(r.date) : \
                                                    reminder.date.to_date
        
      end
      
    else

      save_dx()
            
    end

    # delete expired non-recurring reminders
    @reminders.reject! {|x|  x.date.to_time < @now if not x.recurring }
    
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