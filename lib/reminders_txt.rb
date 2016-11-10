#!/usr/bin/env ruby

# file: reminders_txt.rb


require 'recordx'
require 'app-routes'
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
  
  def initialize(s, now=Time.now)
    
    @raw_input = s
    super()
    @params = {input: s}
    expressions(@params)
    buffer = s[2..-1]

    @expressions = buffer.inject([]) do |r, x|  
      if (x.length > 1) then
        @params[:input] = x
        rx = find_expression(x) 
        rx.input = x
        r << rx
      end
      r
    end
  end
  
  def refresh()
    
    a = @expressions.sort_by do |x| 
      x.date.is_a?(Time) ? x.date : Chronic.parse(x.date)
    end
    
    @raw_input[0..2].join + a.map(&:input).join()
  end
    
  protected

  def expressions(params) 

    
    # some event every 2 weeks
    # some event every 2 weeks at 6am starting from 14th Jan
    # some event every 2 weeks at 6am starting from 18th Feb until 28th Oct
    # some event every 2nd Monday (starting 7th Nov 2016)
    # some event every 2nd Monday (starting 7th Nov until 3rd Dec)


    starting = /(?:\(?\s*starting (\d+\w{2} \w+\s*\w*)(?: until (.*))?\s*\))?/

    get /^(.*)(every \w+ \w+(?: at (\d+am) )?)\s*#{starting}/ do \
                                                |title, recurring, time, date, end_date|
      
      input = params[:input]
      
      if recurring =~ /day|week/ then
        
        earlier_date = Chronic.parse(date)
        new_date = CronFormat.new(ChronicCron.new(recurring).to_expression, earlier_date).to_time
        input.gsub!(date, new_date.strftime("#{new_date.day.ordinal} %b %Y"))        
        date = new_date
      end
      

      RecordX.new input: input, title: title, recurring: recurring, date: date, end_date: end_date
      #[0, title, recurring, time, date, end_date].inspect
    end
    
    # some meeting 3rd thursday of the month at 7:30pm
    # some meeting First thursday of the month at 7:30pm
    get /(.*)\s+(\w+ \w+day of (?:the|every) month at .*)/ do |title, recurring|
      
      RecordX.new input: '', title: title, recurring: recurring
      #[1, title, recurring].inspect
    end        
 
    # some important day 24th Mar
    get /(.*)\s+(\d+.*)/ do |title, date|
      
      RecordX.new input: '', title: title, date: date
      #[2, title, date].inspect
    end
    
    # 27-Mar@1436 some important day
    get /(\d[^\s]+)\s+(.*)/ do |date, title|

      RecordX.new input: '', title: title, date: date
      #[3, title, date].inspect
    end    
    
    # e.g. 04-Aug@12:34
    get '*' do

      'pattern unrecognised'
    end


  end
  
  alias find_expression run_route
  
end

