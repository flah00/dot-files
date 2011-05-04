#!/usr/bin/env ruby

if ENV['DATA']
  #ARGF.shift
  ARGF.each_with_index do |line, idx|
    next unless line =~ /^\s*\w/
    puts line.sub(/^\s*(.*)/, '| \1 |')
  end
elsif ENV['RUBY_FORM']
  ARGF.each_with_index do |line, idx|
    next unless line =~ /^\s*\w/
    line.chomp!
    header = []
    data = []
    # id: 958, network_offer_id: 2, created_at: "2011-03-14 17:06:04", updated_at: "2011-03-14 20:26:11", budget: 10, campaign_id: 912, external_id: "6002997886404"
    line.split(',').each do |couple|
      key,val = couple.split(':', 2)
      header << key.strip
      data << val.gsub(/['"]/,'').strip
    end
    header.zip(data).each do |arr|
      puts '| '+arr.join(' | ')+' |'
    end
  end

elsif ENV['RUBY']
  ARGF.each_with_index do |line, idx|
    next unless line =~ /^\s*\w/
    line.chomp!
    header = []
    data = []
    # id: 958, network_offer_id: 2, created_at: "2011-03-14 17:06:04", updated_at: "2011-03-14 20:26:11", budget: 10, campaign_id: 912, external_id: "6002997886404"
    line.split(',').each do |couple|
      key,val = couple.split(':', 2)
      header << key
      data << val.gsub(/['"]/,'').strip
    end
    puts '| '+ header.join(' | ') +' |'
    puts '| '+ data.join(' | ') +' |'
  end

else
  ## simple tabular format without data
  ARGF.each_with_index { |line,idx| puts line.sub(/^\s*([^|]+\|).*/, '| \1 |') }
end
