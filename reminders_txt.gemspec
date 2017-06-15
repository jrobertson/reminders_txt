Gem::Specification.new do |s|
  s.name = 'reminders_txt'
  s.version = '0.4.2'
  s.summary = 'Reads and updates diary reminders from a plain text file'
  s.authors = ['James Robertson']
  s.files = Dir['lib/reminders_txt.rb']
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.22')
  s.add_runtime_dependency('event_nlp', '~> 0.2', '>=0.2.2')
  s.add_runtime_dependency('chronic_cron', '~> 0.3', '>=0.3.6')
  s.signing_key = '../privatekeys/reminders_txt.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/reminders_txt'
end
