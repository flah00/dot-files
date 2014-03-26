#!/usr/bin/env ruby
require 'optparse'

$options = {
  dry: false,
  force: false,
  refspec: 'HEAD^',
}

OptionParser.new do |opts|
  opts.banner = "Usage chef-update.rb [options]"

  opts.on("-n", "--dry", "Do not do anything") do |v|
    $options[:dry] = v
  end

  opts.on("-f", "--[no-]force", "Forcefully install cookbooks") do |v|
    $options[:force] = v
  end

  opts.on("-r REFSPEC", "--refspec=REFSPEC", "Diff against which refspec, default HEAD^") do |v|
    $options[:refspec] = v
  end

end.parse!

def run_command(str)
  puts str
  puts `#{str}` unless $options[:dry]
end

files = `git diff #{$options[:refspec]} | grep ^diff | awk '{print$3}' | sed 's,a/,,'`.split("\n")

roles = []
envs  = []
books = []

files.each do |file|
  if file =~ /^roles/
    roles << file
  elsif file =~ /^environments/
    envs << file
  elsif file =~ /^cookbooks/
    books << file.sub(%r{cookbooks/([^/]+)/.*}, '\1')
  end
end

run_command("knife role from file #{roles.join(' ')}") if roles.any?
run_command("knife environment from file #{envs.join(' ')}") if envs.any?
books.each do |book|
  if $options[:force]
    run_command "knife cookbook upload #{book} --force"
  else
    run_command "rake upload_cookbook[#{book}]"
  end
end
