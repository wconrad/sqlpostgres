require 'forwardable'

module TestSupport
  class TestConfig

    extend Forwardable

    def initialize
      @config = load_config
    end

    def_delegator :@config, :[]

    private

    PATH = File.expand_path('../config/config.yml',
                            File.dirname(__FILE__))

    def load_config
      YAML.load_file(PATH)
    end

  end
end
