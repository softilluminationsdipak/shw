# config valid only for current version of Capistrano
lock '3.4.0'

SSHKit.config.command_map[:rake] = 'bundle exec rake'
SSHKit.config.command_map[:rails] = 'bundle exec rails'


set :application, 'emr'
set :repo_url, 'git@github.com:softilluminationsdipak/AngularDemo.git'

set :rvm_type, :user

set :rvm_ruby_version, 'ruby-2.3.0'

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/var/www/my_app_name'
set :rvm_roles, :all

# Default value for :scm is :git
# set :scm, :git
set :deploy_to, '/var/www/emr'
# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug

set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

set :use_sudo, true

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')
set :linked_files, %w( config/database.yml )

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'public/reports')

set :bundle_binstubs, nil
# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc "Update the crontab file"
  task :update_crontab do
    on roles(:web, :app, :db) do
      #run "cd #{release_path} && whenever --update-crontab report_builder"
      execute 'crontab -r', raise_on_non_zero_exit: false
      within release_path do
        execute :bundle, :exec,'whenever --update-crontab', raise_on_non_zero_exit: false
      end
    end
  end

  after :deploy, "deploy:update_crontab"

  desc 'Cleanup expired assets'
  task :cleanup_assets => [:set_rails_env] do
    next unless fetch(:keep_assets)
    on release_roles(fetch(:assets_roles)) do
     within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "'assets:clean[#{fetch(:keep_assets)}]'"
        end
      end
    end
  end
  after 'deploy:updated', 'deploy:cleanup_assets'
  
  desc 'Clobber assets'
    task :clobber_assets => [:set_rails_env] do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "assets:clobber"
          end
        end
      end
    end
  after 'deploy:updated', 'deploy:clobber_assets'

  desc 'Compile all the assets named'
   task :precompile do
     on release_roles(fetch(:assets_roles)) do
       within release_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, "assets:precompile"
          end
        end
      end
    end
  after 'deploy:updated', 'deploy:precompile'    
end
