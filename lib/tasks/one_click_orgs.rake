namespace :oco do
  desc "Generate installation-specific config files for One Click Orgs."
  task :generate_config do
    require 'fileutils'
    
    # Returns an absolute filename given path elements relative to the config directory
    def config_dir(*path_elements)
      path_elements.unshift(File.expand_path('../../../config', __FILE__))
      File.join(path_elements)
    end
    
    if File.exist? config_dir('database.yml')
      STDOUT.puts "config/database.yml already exists"
    else
      STDOUT.puts "Creating config/database.yml"
      FileUtils.cp config_dir('database.yml.sample'), config_dir('database.yml')
    end
    
    if File.exist? config_dir('initializers', 'local_settings.rb')
      STDOUT.puts "config/initializers/local_settings.rb already exists"
    else
      STDOUT.puts "Creating config/initializers/local_settings.rb"
      FileUtils.cp config_dir('initializers', 'local_settings.rb.sample'), config_dir('initializers', 'local_settings.rb')
      
      require 'active_support/secure_random'
      code = File.read(config_dir('initializers', 'local_settings.rb'))
      code.sub!('YOUR_SECRET_HERE', ActiveSupport::SecureRandom.hex(64))
      File.open(config_dir('initializers', 'local_settings.rb'), 'w'){|file| file << code}
    end
  end

  desc "Generate a list of contributors"
  task :contributors do
    File.open('doc/CONTRIBUTORS.txt', 'w') do |file|
      file << `git shortlog -nse`.gsub(/^\s+\d+\s+/, '')
    end
  end
  
  namespace :dev do
    desc "Create an active association, for development/testing purposes"
    task :create_association => :environment do
      unless OneClickOrgs::Setup.complete?
        STDERR.puts <<-EOE

You must go through the application setup process before creating an
association.

Start the application server (e.g. 'bundle exec rails server')
and visit the site in your browser (usually at http://localhost:3000 ).
        EOE
        exit
      end
      
      password = ENV['PASSWORD'] || "password"
      
      require 'spec/support/machinist'
      require 'spec/support/blueprints'
      
      # The blueprints use Sham to generate the same set of fake values in
      # order each time the tests are run. However, this will cause uniquness 
      # validation errors here if this task has already been run before.
      # So, we skip Sham for the necessary attributes.
      association = Association.make(
        :subdomain => Faker::Internet.domain_word
      )
      association.active!
      
      member_class = association.member_classes.find_by_name("Member")
      members = association.members.make_n(3,
        :member_class => member_class,
        :password => password,
        :password_confirmation => password
      )
      
      # TODO Should we make a passed FoundAssociationProposal as well,
      # for total authenticity?
      
      STDOUT.puts "Association '#{organisation.name}' created:"
      STDOUT.puts "  #{organisation.domain}"
      STDOUT.puts "Log in with:"
      STDOUT.puts "  Email: #{members.first.email}"
      STDOUT.puts "  Password: #{password}"
    end
  end
end
