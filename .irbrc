require 'pp'
require 'irb/completion'
load File.expand_path("~/.irbrc_adaptly")

# IRB will now know your window size changed...
#$: << Dir["#{ENV['GEM_HOME'].sub(/(@[^\/]+|$)/,'@global')}/gems/ruby-terminfo*/lib"].last if ! Object.const_defined? "TermInfo"
#require 'terminfo'
#Signal.trap('SIGWINCH', proc { Readline.set_screen_size(TermInfo.screen_size[0], TermInfo.screen_size[1]) }) if Object.const_defined? "TermInfo"

## Just for Rails...
#if Object.const_defined? "Rails"
  #rails_root = Rails.root.basename.to_s
  #IRB.conf[:PROMPT] ||= {}
  #IRB.conf[:PROMPT][:RAILS] = {
    #:PROMPT_I    => "#{rails_root}> ",
    #:PROMPT_N    => "#{rails_root}> ",
    #:PROMPT_S    => "#{rails_root}? ",
    #:PROMPT_C    => "#{rails_root}* ",
    #:RETURN      => "=> %s\n" ,
    #:AUTO_INDENT => true
  #}
  #IRB.conf[:PROMPT_MODE] = :RAILS
#end

# vim:ft=ruby:
