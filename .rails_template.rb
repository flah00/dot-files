run('sed \'s/\(^[[:space:]]*config.filter_param.*\)/\1\\
    config.generators do |g|\\
      g.orm :active_record\\
      g.test_framework :rspec\\
      g.template_engine :haml, :fixture => true, :views => false, :helpers => false\\
      g.fixture_replacement :factory_girl\\
    end/\' config/application.rb > tmp/application.rb')
run('mv tmp/application.rb config')

run "rm README"
file "README.md", <<-'EOT'
EOT

#gem 'rails',              :version => '~>3.0.7'
gem 'central_logger',     :git => 'git://github.com/flah00/mongo_db_logger.git', :tag => 'v0.3.5'
gem 'haml'
gem 'jquery-rails'
gem 'mongoid'
gem 'sqlite3-ruby'
gem 'thin'
gem 'capybara',           :group => :test
gem 'cucumber-rails',     :group => :test
gem 'database_cleaner',   :group => :test
gem 'fakeweb',            :group => :test
gem 'launchy',            :group => :test
gem 'pickle',             :group => :test
gem 'rspec-rails',        :group => :test,        :version => '>= 2.1.0'
gem 'annotate',           :group => :development
gem 'autotest',           :group => :development
gem 'autotest-fsevent',   :group => :development
gem 'autotest-growl',     :group => :development
gem 'factory_girl_rails', :group => :development, :version => '1.0'
gem 'haml-rails',         :group => :development
gem 'launchy',            :group => :development
gem 'rails3-generators',  :group => :development, :git => 'git://github.com/indirect/rails3-generators.git'
gem 'rspec-rails',        :group => :development, :version => '>= 2.1.0'
gem 'ruby-debug19',       :group => :development

current_ruby = %x{rvm list}.match(/^=>\s+(.*)\s\[/)[1].strip
run "rvm gemset create #{app_name}"
run "rvm #{current_ruby}@#{app_name} gem install bundler"
run "rvm #{current_ruby}@#{app_name} -S bundle install"

file ".rvmrc", <<-EOT
rvm use #{current_ruby}@#{app_name}
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
.bundle
db/*.sqlite3
tmp/**/*
tmp/*
doc/api
doc/app
*.sw[pno]
*~
public/uploads/**/*
*.orig
*.rej
vendor/cache/*
EOT

file "config/central_logger.yml", <<-'EOT'
defaults: &defaults
  mongo:
    capsize: <%= 2.megabytes %>
    database: <%= "adaptly_#{Rails.env}" %>

development:
  mongo:
    capsize: <%= 2.megabytes %>
    database: <%= "adaptly_#{Rails.env}" %>

test:
  <<: *defaults

production:
  mongo:
    capsize: <%= 10.megabytes %>
    uri: <%= ENV['MONGOHQ_URL'] %>

EOT

file "config/mongoid.yml", <<-'EOT'
defaults: &defaults
  host: localhost
  # slaves:
  #   - host: slave1.local
  #     port: 27018

development:
  <<: *defaults
  database: default_development

test:
  <<: *defaults
  database: default_test

# set these environment variables on your prod server
production:
  uri: <%= ENV['MONGOHQ_URL'] %> 
EOT

run "rvm #{current_ruby}@#{app_name} -S rails g cucumber:install"
run "rvm #{current_ruby}@#{app_name} -S rails g jquery:install"
run "rvm #{current_ruby}@#{app_name} -S rails g pickle"
run "rvm #{current_ruby}@#{app_name} -S rails g rspec:install"

#run "rvm #{current_ruby}@#{app_name} -S rails generate scaffold user name:string password:string"
#route "root :to => 'user#index'"
#run "rvm #{current_ruby}@#{app_name} -S rake db:migrate"
run "rm public/index.html"

run "git init"
run "git add ."
run "git commit -m 'init'"
