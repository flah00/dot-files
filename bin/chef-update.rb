#!/usr/bin/env ruby
require 'optparse'

$options = {
  dry: false,
  force: false,
  refspec: 'HEAD^',
  exclude: []
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

  opts.on("-e FILE", "--exclude=FILE", "Exclude files") do |v|
    $options[:exclude] << v
  end

end.parse!

def run_command(str)
  puts str
  puts `#{str}` unless $options[:dry]
end

def exclude_files(list, root=nil)
  l = list.reject{|l| $options[:exclude].include?(l) }
  l.reject{|f| ! File.exist?(root.nil? ? f : "#{root}/#{f}") }
end

files = `git diff #{$options[:refspec]} | grep ^diff | awk '{print$3}' | sed 's,a/,,'`.split("\n")

roles = {}
envs  = {}
books = {}

files.each do |file|
  if file =~ /^roles/
    roles[file] = 1
  elsif file =~ /^environments/
    envs[file] = 1
  elsif file =~ /^cookbooks/
    books[file.sub(%r{cookbooks/([^/]+)/.*}, '\1')] = 1
  end
end

if roles.any?
  files = exclude_files(roles.keys)
  run_command("knife role from file #{files.join(' ')}")
end

if envs.any?
  files = exclude_files(envs.keys)
  run_command("knife environment from file #{files.join(' ')}")
end

files = exclude_files(books.keys, "cookbooks")
files.each do |book|
  if $options[:force]
    run_command "knife cookbook upload #{book} --force"
  else
    run_command "rake upload_cookbook[#{book}]"
  end
end
