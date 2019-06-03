require 'swagger/base'
require 'fuzzy_match'

module Swagger
  module RackHelpers
    def request_spec(env: nil)
      path = env['REQUEST_PATH']
      verb = env['REQUEST_METHOD'].downcase
      spec_path = match_string(@spec['paths'], path)
      return nil if spec_path.nil?

      spec = @spec['paths'][spec_path][verb]

      return nil if spec.nil?

      {
        path: spec_path,
        captures: get_captures(spec_path, path),
        spec: spec
      }
    end

    private

    def match_string(paths, path)
      groupings = paths.keys.map do |key|
        key.split('/').map do |k|
          Regexp.new("#{k}/", 'i')
        end
      end.flatten

      FuzzyMatch.new(paths.keys, groupings: groupings).find(path)
    end

    def get_captures(spec_path, path)
      re      = spec_path.gsub(/\{([^}]+)\}/, "(?<\\1>.+?)")
      matches = Regexp.new("^#{re}$").match(path)
      return nil if matches.nil?
      captures = matches.captures
      Hash[matches.names.zip(captures)]
    end
  end

  Base.send(:include, RackHelpers)
end
