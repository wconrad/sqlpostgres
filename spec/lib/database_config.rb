require 'forwardable'
require 'yaml'

module TestSupport
  class DatabaseConfig

    extend Forwardable

    def initialize
      @config = load_config
    end

    def_delegator :@config, :map

    private

    PATH = File.expand_path('../config/database.yml',
                            File.dirname(__FILE__))
    TEMPLATE_PATH = PATH + '.template'

    def load_config
      YAML.load_file(PATH)
    rescue Errno::ENOENT
      print_config_instructions
      raise 'Missing database config'
    end

    def print_config_instructions
      puts "Missing config at #{PATH}"
      puts "Please create it by copying and editing #{TEMPLATE_PATH}"
    end

  end
end
