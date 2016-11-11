# Introducing the reminders_txt gem

The reminders_txt gem makes it convenient to store reminders in a plain text file called reminders.txt. It can read reminder dates to sort reminders in reverse chronological order, as well as remove expired reminders, and set new dates for recurring reminders.

    require 'reminders_txt'

    filepath = '/home/james/jamesrobertson.eu/reminders/reminders.txt'
    rt = RemindersTxt.new(filepath, dxfilepath: 'reminders.xml')
    puts rt.to_s


file: reminders.txt

<pre>
reminders.txt
=============

Hamster's birthday 2nd Nov *
Meeting in room 3 5th Nov
Meeting in room 5 14th Nov
green bin out every 2nd Monday (starting 7th Nov 2016)
mother's day 14th April *
Networking X meeting 26th Feb
Valentine's Day 14th Feb *
</pre>

output:

<pre>
reminders.txt
=============

Meeting in room 5 14th Nov
green bin out every 2nd Monday (starting 21st Nov 2016)
Valentine's Day 14th Feb *
Networking X meeting 26th Feb
mother's day 14th April *
Hamster's birthday 2nd Nov *
</pre>

The reminders.xml file shown below maintains a working copy of the most recent reminders and makes it convient to query a reminder by title, date, etc.

file: reminders.xml

<pre>
&lt;?xml version='1.0' encoding='UTF-8'?&gt;
&lt;reminders&gt;
  &lt;summary&gt;
    &lt;recordx_type&gt;dynarex&lt;/recordx_type&gt;
    &lt;format_mask&gt;[!input] [!title] [!recurring] [!date] [!end_date]&lt;/format_mask&gt;
    &lt;schema&gt;reminders/reminder(input, title, recurring, date, end_date)&lt;/schema&gt;
    &lt;default_key&gt;input&lt;/default_key&gt;
  &lt;/summary&gt;
  &lt;records&gt;
    &lt;reminder id='1' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;Meeting in room 5 14th Nov&lt;/input&gt;
      &lt;title&gt;Meeting in room 5&lt;/title&gt;
      &lt;recurring/&gt;
      &lt;date&gt;2016-11-14 12:00:00 +0000&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
    &lt;reminder id='2' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;green bin out every 2nd Monday (starting 21st Nov 2016)&lt;/input&gt;
      &lt;title&gt;green bin out &lt;/title&gt;
      &lt;recurring&gt;every 2nd Monday&lt;/recurring&gt;
      &lt;date&gt;2016-11-21 12:00:00 +0000&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
    &lt;reminder id='3' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;Valentine's Day 14th Feb *&lt;/input&gt;
      &lt;title&gt;Valentine's Day&lt;/title&gt;
      &lt;recurring/&gt;
      &lt;date&gt;2017-02-14 12:00:00 +0000&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
    &lt;reminder id='4' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;Networking X meeting 26th Feb&lt;/input&gt;
      &lt;title&gt;Networking X meeting&lt;/title&gt;
      &lt;recurring/&gt;
      &lt;date&gt;2017-02-26 12:00:00 +0000&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
    &lt;reminder id='5' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;mother's day 14th April *&lt;/input&gt;
      &lt;title&gt;mother's day&lt;/title&gt;
      &lt;recurring/&gt;
      &lt;date&gt;2017-04-14 12:00:00 +0100&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
    &lt;reminder id='6' created='2016-11-11 12:24:27 +0000' last_modified=''&gt;
      &lt;input&gt;Hamster's birthday 2nd Nov *&lt;/input&gt;
      &lt;title&gt;Hamster's birthday&lt;/title&gt;
      &lt;recurring/&gt;
      &lt;date&gt;2017-11-02 12:00:00 +0000&lt;/date&gt;
      &lt;end_date/&gt;
    &lt;/reminder&gt;
  &lt;/records&gt;
&lt;/reminders&gt;
</pre>
  

## Resources

* reminders_txt https://rubygems.org/gems/reminders_txt

reminders gem reminderstxt reminders_txt events
