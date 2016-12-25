Gem::Specification.new do |s|
  s.name = 'reminders_txt'
  s.version = '0.3.8'
  s.summary = 'Reads and updates diary reminders from a plain text file'
  s.authors = ['James Robertson']
  s.files = Dir['lib/reminders_txt.rb']
  s.add_runtime_dependency('dynarex', '~> 1.7', '>=1.7.15')
  s.add_runtime_dependency('app-routes', '~> 0.1', '>=0.1.18')
  s.add_runtime_dependency('chronic_cron', '~> 0.3', '>=0.3.2')
  s.signing_key = '../privatekeys/reminders_txt.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/reminders_txt'
end
