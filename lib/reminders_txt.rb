#!/usr/bin/env ruby

# file: reminders_txt.rb


require 'dynarex'
require 'event_nlp'
require 'digest/md5'
require 'human_speakable'
require 'rxfreadwrite'


class RemindersTxtException < Exception

end


class RemindersTxt
  using ColouredText
  include RXFReadWriteModule

  attr_reader :reminders, :dx

  def initialize(raw_s='reminders.txt', now: Time.now, debug: false)

    super()

    @now, @debug = now, debug

    puts ('@now: ' + @now.inspect).debug if @debug


    @filepath = raw_s

    if raw_s.lines.length > 1 then

      if raw_s.lstrip[0] == '<' then

        @filepath = 'reminders.xml'
        @dx = Dynarex.new raw_s

      else

        @filepath = File.join(DirX.pwd, 'reminders.txt')
        @dxfilepath = @filepath.sub(/.txt$/,'.xml')

        @dx = Dynarex.new
        import_txt(raw_s)

      end

    elsif File.extname(@filepath) == '.txt'

      s = FileX.read @filepath
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

  def after(d)

    date = d.is_a?(String) ? Chronic.parse(d).to_datetime : d
    @dx.filter {|x| DateTime.parse(x.date) > date}

  end

  def before(d)

    future_date = d.is_a?(String) ? Chronic.parse(d).to_datetime : d
    @dx.filter {|x| DateTime.parse(x.date) < future_date}

  end

  def find(s)
    @dx.filter {|x| x.title =~ /#{s}/i}
  end

  def upcoming(ndays=5, days: ndays, months: nil)

    next_date = if months then
      @now.to_datetime >> months.to_i
    else
      ((@now.to_date + days.to_i + 1).to_time - 1).to_datetime
    end

    @dx.filter {|x| DateTime.parse(x.date) <= next_date}
  end

  def updated?()
    @updated
  end

  def today()
    upcoming 0
  end

  def tomorrow()
    upcoming days: 1
  end

  def this_week()
    upcoming days: 6
  end

  alias weekahead this_week

  def this_month()
    upcoming months: 1
  end

  def this_year()
    upcoming months: 12
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

    puts 'inside import_txt' if @debug
    @file_contents = s
    buffer = s.lines[2..-1]

    @reminders = buffer.inject([]) do |r, x|

      puts 'x: ' + x.inspect if @debug
      x.strip!

      if (x.length > 1) then

        puts '@now:' + @now.inspect if @debug

        rx = EventNlp.new(@now, params: {input: x}, debug: @debug).parse(x)
        puts ('rx: ' + rx.inspect).debug if @debug
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

    puts 'inside refresh()' if @debug

    reminders = @reminders.clone
    # if XML file doesn't exist, create it

    if FileX.exists? @dxfilepath then

      @dx = Dynarex.new @dxfilepath

      @reminders.each do |reminder|

        s = reminder.input
        puts ('refresh() checking s: ' + s).debug if @debug
        r = @dx.find_by_input s

        # it is on file and it's not a recurring or annual event?
        # use the date from file if the record exists

        if (r and r.recurring.empty? and not s[/\*$/]) then
          DateTime.parse(r.date)
        else

          if reminder.date then
            reminder.date.to_datetime
          else
            raise RemindersTxtException, 'nil date  for reminder : ' \
                + reminder.inspect
          end
        end

      end

    else

      save_dx()

    end

    # delete expired non-recurring reminders
    @reminders.reject! do |x|

      if @debug then
        puts 'rejects filter: '
        puts '  x.input: ' + x.input.inspect
        puts '  x.date.to_time: '  + x.date.to_time.inspect
      end

      x.date.to_time < @now if not x.recurring

    end

    @reminders.sort_by!(&:date)

    # did the reminders change?
    puts 'self.to_s: ' + self.to_s if @debug

    h1 = (Digest::MD5.new << self.to_s).to_s
    h2 = (Digest::MD5.new << @file_contents).to_s

    b = h1 != h2

    if @debug then
      puts 'reminders: ' + reminders.inspect
      puts '@reminders: ' + @reminders.inspect
    end

    if b or @reminders != reminders then

      save_dx()
      FileX.write File.join(File.dirname(@filepath), 'reminders.txt'), self.to_s
      @updated = true
    else
      puts 'no update'
    end

    [:refresh, b]

  end

  def save_detail()

    # fetch the notes file if it exists
    filepath = File.dirname @dxfilepath

    notesfile = File.join(filepath, 'reminder_notes.xml')
    return unless FileX.exists? notesfile

    dx = Dynarex.new notesfile

    h = dx.all.inject({}) do |r,x|

      a = x.info.lines
      tag = a.shift[/\w+/]
      body = a.join.strip

      r.merge(tag.to_sym => body)

    end

    rows = @dx.all.map do |x|
      hashtag = x.title[/#(\w+)/,1]
      hashtag ? x.to_h.merge(info: h[hashtag.to_sym]) : x.to_h
    end

    dx2 = Dynarex.new 'reminders/reminder(input, title, recurring, ' +
        'date, end_date, venue, info)'
    dx2.import rows
    dx2.save File.join(filepath, 'reminder_details.xml')

  end

  def save_dx()

    @dx = Dynarex.new(
      'reminders/reminder(input, title, recurring, date, end_date, venue)')
    @reminders.each {|x| @dx.create x.to_h}
    @dx.save @dxfilepath

    save_detail()

  end


end

class RemindersTxtVoice < RemindersTxt
  using HumanSpeakable

  def weekahead() plain_talk(super) end
  def today()     plain_talk(super) end
  def tomorrow()  plain_talk(super) end

  private

  def plain_talk(entries)

    s = entries.all.map do |x|
      date = DateTime.parse(x.date)
      "you are at %s, %s at %s." % [(x.venue.empty? ? x.title : x.venue), \
                                    date.humanize, date.to_time.humanize]
    end.join(" Then ")

    s.sub!(/^./){|x| x.upcase}

  end

end
