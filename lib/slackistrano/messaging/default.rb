module Slackistrano
  module Messaging
    class Default < Base
      def payload_for_updating
        nil
      end

      def payload_for_reverting
        nil
      end

      def payload_for_updated
        {
          attachments: [{
            color: 'good',
            title: "#{application} deployed :shipit:",
            fields: [{
              title: 'Environment',
              value: stage,
              short: true
            }, {
              title: 'Branch',
              value: branch,
              short: true
            }, {
              title: 'Deployer',
              value: deployer,
              short: true
            }, {
              title: 'Time',
              value: elapsed_time,
              short: true
            }, {
              title: 'Commit',
              value: fetch(:current_revision, ''),
              short: true
            }, {
              title: 'Changes',
              value: fetch(:changelog, []).join("\n")
            }],
            fallback: super[:text]
          }],
          text: "<!here> Application Deployed!"
        }
      end

      def payload_for_reverted
        super
      end

      def payload_for_failed
        payload = super
        payload[:text] = "[#{stage}] #{application} :fire: #{deployer} has failed to #{deploying? ? 'deploy' : 'rollback'} branch #{branch}"
        payload
      end

      def deployer
        name = `git config user.name`.strip
        name = nil if name.empty?
        name ||= Etc.getpwnam(ENV['USER']).gecos || ENV['USER'] || ENV['USERNAME']
        name
      end

      def channels_for(action)
        super
      end
    end
  end
end
