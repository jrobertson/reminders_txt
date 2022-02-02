Gem::Specification.new do |s|
  s.name = 'reminders_txt'
  s.version = '0.7.0'
  s.summary = 'Reads and updates diary reminders from a plain text file'
  s.authors = ['James Robertson']
  s.files = Dir['lib/reminders_txt.rb']
  s.add_runtime_dependency('dynarex', '~> 1.9', '>=1.9.2')
  s.add_runtime_dependency('event_nlp', '~> 0.6', '>=0.6.0')
  s.add_runtime_dependency('human_speakable', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/reminders_txt.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/reminders_txt'
end
