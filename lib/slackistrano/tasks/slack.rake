require 'git'
require 'colorize'

namespace :slack do
  namespace :deploy do
    desc 'Notify about updating deploy'
    task :updating do
      Slackistrano::Capistrano.new(self).run(:updating)
    end

    desc 'Notify about reverting deploy'
    task :reverting do
      Slackistrano::Capistrano.new(self).run(:reverting)
    end

    desc 'Notify about updated deploy'
    task :updated do
      unless fetch(:changelog, []).size == 0
        Slackistrano::Capistrano.new(self).run(:updated)
      end
    end

    desc 'Notify about reverted deploy'
    task :reverted do
      Slackistrano::Capistrano.new(self).run(:reverted)
    end

    desc 'Notify about failed deploy'
    task :failed do
      Slackistrano::Capistrano.new(self).run(:failed)
    end

    desc 'Test Slack integration'
    task :test => %i[updating updated reverting reverted failed] do
      # all tasks run as dependencies
    end

    desc 'Fetch changelog given a start and end git commits'
    task :fetch_changelog do
      current_revision = fetch(:current_revision).to_s
      previous_revision = fetch(:previous_revision).to_s

      if (current_revision.empty? || previous_revision.empty?)
        puts "Could not get the git commits".yellow
        next
      end

      if (current_revision == previous_revision)
        puts "No changes found".yellow
        next
      end

      git = Git.open('.')
      logs = git.log.between(previous_revision, current_revision)
      if (logs.nil? || logs.size == 0)
        puts "No git logs found from #{previous_revision} to #{current_revision}".yellow
        next
      end

      commit_messages = logs.map(&:message)

      changelog = commit_messages.map do |message|
        if message =~ /Merge branch/
          message.split("\n").reject(&:empty?)[1]
        else
          match = m.match(/\[\#(\d{4,5})\]/)
          next unless match

          message
        end
      end.compact.uniq

      puts "Found #{changelog.size} commits for changelog".blue
      set :changelog, changelog
    end
  end
end

after 'deploy:finishing', 'slack:deploy:fetch_changelog'
after 'slack:deploy:fetch_changelog', 'slack:deploy:updated'
after 'deploy:failed', 'slack:deploy:failed'
after 'deploy:finishing_rollback', 'slack:deploy:reverted'
