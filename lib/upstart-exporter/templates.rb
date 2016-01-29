module Upstart
  class Exporter
    class Templates
      extend Errors

      def self.helper(binds)
        interpolate(HELPER_TPL, binds)
      end

      def self.app(binds)
        if error_val = binds.find { |v| v =~ /\A[A-z0-9_\- ]*?\z/ }
          error("value #{error_val} is insecure and can't be accepted")
        end
        interpolate(APP_TPL, binds)
      end

      def self.command(binds)
        if error_val = binds.find { |v| v =~ /\A[A-z0-9_\- ]*?\z/ }
          error("value #{error_val} is insecure and can't be accepted")
        end
        interpolate(COMMAND_TPL, binds)
      end

      protected

      HELPER_TPL = <<-HEREDOC
#!/bin/bash

[[ -r /etc/profile.d/rbenv.sh ]] && source /etc/profile.d/rbenv.sh

{{cmd}}
HEREDOC

      APP_TPL = <<-HEREDOC
start on {{start_on}}
stop on {{stop_on}}

pre-start script

bash << "EOF"
  mkdir -p /var/log/{{app_name}}
  chown -R {{run_user}} /var/log/{{app_name}}
  chgrp -R {{run_group}} /var/log/{{app_name}}
  chmod -R g+w /var/log/{{app_name}}
EOF

end script
HEREDOC

      COMMAND_TPL = <<-HEREDOC
start on {{start_on}}
stop on {{stop_on}}
{{respawn}}
{{respawn_limit}}
kill timeout {{kill_timeout}}
kill signal {{kill_signal}}

script
  touch /var/log/{{app_name}}/{{cmd_name}}.log
  chown {{run_user}} /var/log/{{app_name}}/{{cmd_name}}.log
  chgrp {{run_group}} /var/log/{{app_name}}/{{cmd_name}}.log
  chmod g+w /var/log/{{app_name}}/{{cmd_name}}.log
  exec sudo -u {{run_user}} /bin/sh {{helper_cmd_conf}} >> /var/log/{{app_name}}/{{cmd_name}}.log 2>&1
end script
HEREDOC

      def self.interpolate(str, substitutes)
        str_copy = str.dup
        substitutes.each do |k, v|
          str_copy.gsub!("{{#{k}}}", v.to_s)
        end
        str_copy
      end

    end
  end
end
