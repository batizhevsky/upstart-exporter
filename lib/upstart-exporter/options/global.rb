module Upstart::Exporter::Options
  class Global < Hash
    include Upstart::Exporter::Errors

    DEFAULTS = {
      'helper_dir' => '/var/local/upstart_helpers/',
      'upstart_dir' => '/etc/init/',
      'run_user' => 'service',
      'run_group' => 'service',
      'prefix' => 'fb-',
      'start_on_runlevel' => '[3]',
      'stop_on_runlevel' => '[3]',
      'kill_timeout' => 30,
      'kill_signal' => 'SIGTERM',
      'respawn' => {
        'count' => 5,
        'interval' => 10
      }
    }

    CONF = '/etc/upstart-exporter.yaml'

    def initialize
      super
      config = if FileTest.file?(CONF)
        YAML::load(File.read(CONF))
      else
        $stderr.puts "#{CONF} not found"
        {}
      end
      error "#{CONF} is not a valid YAML config" unless config.is_a?(Hash)
      DEFAULTS.keys.each do |param|
        value = if config[param]
          config[param]
        else
          $stderr.puts "Param #{param} is not set, taking default value #{DEFAULTS[param]}"
          DEFAULTS[param]
        end
        self[param.to_sym] = value
      end
    end

  end
end
