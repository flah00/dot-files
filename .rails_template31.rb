
## snapshot virgin rails
run "git init"
run "git add ."
run "git commit -m 'init'"

# requires rvm
re = /^=>\s+(.*)\s\[/ 
rvm_list = %x{rvm list}
## use default rvm or assume there's only one and use that
match = rvm_list.match(re)[1] rescue rvm_list.split("\n").last.match(re)[1]
unless match
  $stdout.puts("no suitable rvm ruby install found")
  exit(1)
end
current_ruby = match.strip
 

run('sed \'s/\(^[[:space:]]*config.filter_param.*\)/\1\\
    config.generators do |g|\\
      g.orm :active_record\\
      g.test_framework :rspec\\
      g.template_engine :haml, fixture: true, views: false, helpers: false\\
      g.fixture_replacement :factory_girl\\
    end/\' config/application.rb > tmp/application.rb')
run('mv tmp/application.rb config')

run "git rm README"
file "README.md", <<-'EOT'
EOT

file "Procfile", <<EOT
web: bundle exec thin start -p $PORT
EOT

run "rm Gemfile"
file "Gemfile", <<'EOT'
source 'http://rubygems.org'

gem 'rails', '3.1.1'
gem 'pg'
gem 'thin'
gem 'newrelic_rpm'

gem 'jquery-rails'
gem 'sass-rails', "  ~> 3.1.0"
gem 'uglifier'
#gem 'pjax-rails'
#gem 'coffee-rails', "~> 3.1.0"
#gem 'blueprint-rails'

gem 'formtastic', '~>2.0.0'
gem 'will_paginate', '>3.0'
gem 'devise'
gem 'cancan'

group :development do
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'haml-rails'
  gem 'heroku', '>2.0'
  gem 'web-app-theme', '~> 0.8.0'
end

group :development, :test do
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
  gem 'ruby-debug19', require: 'ruby-debug'
  gem 'factory_girl_rails'
end
EOT

run "rvm gemset create #{app_name}"
run "rvm #{current_ruby}@#{app_name} gem install bundler"
run "rvm #{current_ruby}@#{app_name} -S bundle install"

file ".rvmrc", <<-EOT
rvm use #{current_ruby}@#{app_name}
EOT

run "git rm app/views/layouts/application.html.erb"
file "app/views/layouts/application.html.haml", <<EOT
!!! 5
%head
  %title
    Exp
  = stylesheet_link_tag    "application"
  = javascript_include_tag "application"
  = csrf_meta_tags
%body
  .notice
    = flash[:notice]
  .alert
    = flash[:alert]
  = yield
EOT

file "config/newrelic.yml", <<'EOT'
production:
  error_collector:
    capture_source: true
    enabled: true
    ignore_errors: ActionController::RoutingError
  apdex_t: 0.5
  ssl: false
  monitor_mode: true
  license_key: <%= ENV["NEW_RELIC_LICENSE_KEY"] %>
  developer_mode: false
  app_name: <%= ENV["NEW_RELIC_APP_NAME"] %>
  transaction_tracer:
    record_sql: obfuscated
    enabled: true
    stack_trace_threshold: 0.5
    transaction_threshold: apdex_f
  capture_params: false
  log_level: info
EOT

run "rm .gitignore"
file ".gitignore", <<-EOT
# Packages #
############
# it's better to unpack these files and commit the raw source
# git has its own built in compression methods
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip

# Logs and databases #
######################
*.log
*.sql
*.sqlite
*.dat
*.csv

# OS generated files #
######################
.DS_Store?
ehthumbs.db
Icon?
Thumbs.db

# Rails #
#########
.sass-cache/
.bundle
db/*.sqlite3
tmp/**/*
tmp/*
doc/api
doc/app
*.sw[pno]
*~
public/uploads/**/*
vendor/cache/*
EOT

run "rvm #{current_ruby}@#{app_name} -S rails g cancan:ability"
run "rvm #{current_ruby}@#{app_name} -S rails g formtastic:install"
run "rvm #{current_ruby}@#{app_name} -S rails g rspec:install"

run "git rm public/index.html"

if Dir.exists?("#{ENV['HOME']}/.pow") && %x{which powder} && $?.success?
  %x{powder link}
end

run "git add ."
run "git commit -m 'post-init'"
username = %x{git config github.user}.strip
if username
	run "git remote rm origin"
	run "git remote add origin git@github.com:#{username}/#{app_name}.git"
end

