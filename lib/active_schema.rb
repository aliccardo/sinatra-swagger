# frozen_string_literal: true
require 'ostruct'
require 'i18n'

I18n.config.available_locales = :en
I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '*.yml')]

module ActiveSchema
  class ErrorsFormatter
    attr_reader :errors, :formatted

    def initialize(errors)
      @errors = errors
      @formatted = []
    end

    def format
      errors.each do |error|
        format_error(error)
      end

      formatted
    end

    private

    def format_error(error)
      formatted << ErrorFormatter.new(error).format
    end
  end

  class ErrorFormatter
    attr_reader :error, :key, :message, :options

    def initialize(error)
      @error = OpenStruct.new(error)
      # Default key
      @key = @error.fragment.gsub('#/', '')
      @options = {}
    end

    def format
      begin
        send("format_#{error.failed_attribute.downcase}")
      rescue
        default_format
      end

      OpenStruct.new(key: key, message: message, options: options)
    end

    private

    def format_required
      # Original: did not contain a required property of 'key' in schema
      @key = error.message.split(' in schema')[0].split(' ').last.gsub("'", '')
      @message = :blank
    end

    def format_pattern
      @message = :invalid
    end

    def format_minimum
      # Original: did not have a minimum value of x, inclusively in schema
      count = error.message.split(/, inclusively|exclusively in schema/)[0].split(' ').last
      @message = :greater_than
      @options = { count: count.to_i }
    end

    def format_maximum
      # Original: did not have a maximum value of x, inclusively in schema
      count = error.message.split(/, inclusively|exclusively in schema/)[0].split(' ').last
      @message = :less_than
      @options = { count: count.to_i }
    end

    def format_minlength
      # Original: was not of a minimum string length of 1 in schema
      count = error.message.split(' in schema')[0].split(' ').last
      @message = :too_short
      @options = { count: count.to_i }
    end

    def format_maxlength
      # Original: was not of a maximum string length of 1 in schema
      count = error.message.split(' in schema')[0].split(' ').last
      @message = :too_long
      @options = { count: count.to_i }
    end

    def format_typev4
      #Original: did not match the following type: string in schema
      type = error.message.split(' in schema')[0].split(' ').last
      case type
        when 'integer'
          @message = :not_an_integer
        when 'number'
          @message = :not_a_number
        when 'string'
          @message = :not_a_string
        when 'boolean'
          @message = :not_a_boolean
        else
          @message = :invalid
      end
    end

    def format_enum
      list = error.message.split(' in schema')[0].split('values: ').last
      @message = :inclusion
      @options = { list: list}
    end

    def default_format
      # Show error in logs if we don't yet handle a schema error
      puts 'Unformatted schema error - ' \
                        "TYPE: #{error.failed_attribute}, "\
                        "MESSAGE: #{error.message}"

      @message = :invalid
    end
  end
end
