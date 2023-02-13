#!/usr/bin/env ruby
# Install ruby on debian
#   1. apt-get update
#   2. apt-get install ruby-byebug ruby-csv -y
# Install ruby on fedora
#   1. dnf install -y rubygem-byebug
#
# Break up an ISD CSV report into separate files, using the cluster:NAME in row BO
# You must specify at least one input
# -i CSV   An ISD Container Vulnerability CSV
#          Download the XLS and convert it to CSV
#          https://isd.accenture.com/issues?issueSubcategories=CONTAINERS__Container%26nbspCompliance%20CONTAINERS__Container%26nbspHost%26nbspCompliance%20CONTAINERS__Container%26nbspHost%26nbspVulnerabilities%20CONTAINERS__Container%26nbspImage%26nbspVulnerabilities&isBeta=false&isSecurityException=false&isFalsePositive=false&issueProgress=OPEN&isAllowedList=false&isAstr=null
# You may optionally specify the cluster names to extract
# -c INPUT A file, each line is a cluster name, ie
#          AZEUDKS-I-5524-CACT
#          AZEUDKS-I-6103-ARCA
require 'csv'
require 'pp'
require 'optparse'
#require 'byebug'
options = {date: false, sites: []}
OptionParser.new do |opts|
  opts.on('-c INPUT', '--clusters INPUT', 'file, each line is a cluster name') do |v|
    options[:clusters] = v
  end
  opts.on('-i CSV', '--isd-csv CSV', 'csv input') do |v|
    options[:isd_csv] = v
  end
  opts.on('-s SITEID', '--site SITEID', 'file, each line is a cluster name') do |v|
    options[:sites] += v.split(',')
  end
  opts.on('--date', 'include today\'s date in the filename') do |v|
    options[:date] = true
  end
end.parse!

if options[:clusters].nil?
  f=[]
  File.open(options[:isd_csv], 'r') do |file|
    file.each_line do |line|
      line[/Cluster:(.*)/] and f += $1.split(/[,\n]/)
    end
  end
  f=f.compact.sort.uniq
else
  f=File.open(options[:clusters], 'r') 
end

f.each do |arg|
  s=CSV.open(options[:isd_csv], 'r', headers: true)
  arg.gsub!(/\s/, '')
  arg=arg.chomp
  output=arg
  output+=Time.now.strftime('-%Y-%m-%d') if options[:date]
  output+='.csv'
  print "Checking '#{arg}' "
  CSV.open(output, 'wb') do |o|
    o << s.first.headers
    # find the rows in the source
    r=s.select do |row| 
      row.to_s[/Cluster:\s+[-\w\d,]*#{arg}/i]
    end
    # add the found rows to the output
    r.each{|row| o << row }
    puts "found #{r.count} rows"
  end
end

