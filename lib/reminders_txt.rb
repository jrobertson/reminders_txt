#!/usr/bin/env ruby

# file: reminders_txt.rb


require 'dynarex'
require 'app-routes'
require 'digest/md5'
require 'chronic_cron'


module Ordinals

  refine Fixnum do
    def ordinal
      self.to_s + ( (10...20).include?(self) ? 'th' : 
                    %w{ th st nd rd th th th th th th }[self % 10] )
    end
  end
end



class RemindersTxt
  include AppRoutes
  using Ordinals
  
  attr_reader :expressions
  
  def initialize(filename='reminders.txt', now: Time.now, dxfilepath: 'reminders.xml')
    
    
    s = File.read filename
    @file_contents, @filename = s, filename
    @now = now
    
    Dir.chdir File.dirname(filename)
    
    @dxfilepath = dxfilepath
    
    super()
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
    
    update()
  end
  
  def save_dx()
    
    dx = Dynarex.new('reminders/reminder(input, title, recurring, date, end_date)')
    @reminders.each {|x| dx.create x.to_h}
    dx.save @dxfilepath
    
  end
  
  def refresh()
    
    #@reminders.map! do |x|
    #   x.date = x.date.is_a?(Time) ? x.date : Chronic.parse(x.date)
    #   x
    #end

    # synchronise with the XML file
    # if XML file doesn't exist, create it
    
    if File.exists? @dxfilepath then

      dx = Dynarex.new @dxfilepath
      
      @reminders.map do |reminder|
        s = reminder.input
        r = dx.find_by_input s
        
        # it is on file and it's not an annual event?
        reminder.date = (r and not s[/\*$/]) ? Date.parse(r.date) : reminder.date.to_date
        
        reminder
      end
            
    end

    # delete expired non-recurring reminders
    @reminders.reject! {|x|  x.date.to_time < @now }
    
    @reminders.sort_by!(&:date)
    

    # did the reminders change?
    
    h1 = (Digest::MD5.new << self.to_s).to_s
    h2 = (Digest::MD5.new << @file_contents).to_s

    b = h1 != h2
        
    if b then
      
      save_dx()      
      File.write @filename, self.to_s 

    end
    
    [:refresh, b]
        
  end
  
  def to_s()
    @file_contents.lines[0..2].join + @reminders.map(&:input).join("\n")
  end
  
  alias update refresh
    
  protected

  def expressions(params) 

    
    # some event every 2 weeks
    # some event every 2 weeks at 6am starting from 14th Jan
    # some event every 2 weeks at 6am starting from 18th Feb until 28th Oct
    # some event every 2nd Monday (starting 7th Nov 2016)
    # some event every 2nd Monday (starting 7th Nov until 3rd Dec)


    starting = /(?:\(?\s*starting (\d+\w{2} \w+\s*\w*)(?: until (.*))?\s*\))?/

    get /^(.*)(every \w+ \w+(?: at (\d+am) )?)\s*#{starting}/ do \
                                                |title, recurring, time, raw_date, end_date|
      
      input = params[:input]
      
      d = Chronic.parse(raw_date)
      
      if recurring =~ /day|week/ then
                
        
        if d < @now then
          
          new_date = CronFormat.new(ChronicCron.new(recurring).to_expression, d).to_time
          input.gsub!(raw_date, new_date.strftime("#{new_date.day.ordinal} %b %Y"))        
          d = new_date
          
        end
      end
      

      OpenStruct.new input: input, title: title, recurring: recurring, date: d, end_date: end_date
      #[0, title, recurring, time, date, end_date].inspect
    end
    
    # some meeting 3rd thursday of the month at 7:30pm
    # some meeting First thursday of the month at 7:30pm
    get /(.*)\s+(\w+ \w+day of (?:the|every) month at .*)/ do |title, recurring|
      
      OpenStruct.new input: params[:input], title: title, recurring: recurring
      #[1, title, recurring].inspect
    end        
 
    # some important day 24th Mar
    get /(.*)\s+(\d+[^\*]+)(\*)?/ do |title, raw_date, annualar|

      d = Chronic.parse(raw_date)
      
      if annualar and d < @now then
        d = Chronic.parse(raw_date, now: Time.local(@now.year + 1, 1, 1)) 
      end

      OpenStruct.new input: params[:input], title: title, date: d
      #[2, title, date].inspect
    end
    
    # 27-Mar@1436 some important day
    get /(\d[^\s]+)\s+([^\*]+)(\*)?/ do |raw_date, title, annualar|

      d = Chronic.parse(raw_date)
      
      if annualar and d < @now then
        d = Chronic.parse(raw_date, now: Time.local(@now.year + 1, 1, 1)) 
      end
      
      
      OpenStruct.new input: params[:input], title: title, date: d
      #[3, title, date].inspect
    end    
    
    # e.g. 04-Aug@12:34
    get '*' do

      'pattern unrecognised'
    end


  end
  
  alias find_expression run_route
  
end