require 'sqlpostgres/PgType'

module SqlPostgres

  # This class holds the value of an "interval" column.  Instances are
  # immutable.  
  #
  # The fields of a PgInterval are:
  # * millennia (integer, default 0)
  # * centuries (integer, default 0)
  # * decades (integer, default 0)
  # * years (integer, default 0)
  # * months (integer, default 0)
  # * weeks (integer, default 0)
  # * days (integer, default 0)
  # * hours (integer, default 0)
  # * minutes (integer, default 0)
  # * seconds (integer or float, default 0)
  # * ago (boolean, default false)
  #
  # These fields are set by passing has args to the constructor and can
  # be retrieved using simple accessors:
  #
  #** Example: interval
  #   interval = PgInterval.new('hours'=>1, 'minutes'=>30)
  #   p interval.hours                                      # 1
  #   p interval.minutes                                    # 30
  #   p interval.seconds                                    # 0
  #**

  class PgInterval < PgType

    private

    DATE_FIELDS = [
      "millennia", "centuries", "decades",
      "years", "months", "weeks", "days",
    ]

    TIME_FIELDS = ["hours", "minutes", "seconds"]

    FIELDS = DATE_FIELDS + TIME_FIELDS + ["ago"]

    public

    for field in FIELDS
      eval <<-EOS
      def #{field}
        @values["#{field}"]
      end
      EOS
    end

    class << self

      # Convert a Postgres string (ie "2 days 12:00:00") to a
      # PgInterval instance.

      def from_sql(s)
        begin
          args = {}
          words = s.split
          raise ArgumentError if words.empty?
          while !words.empty?
            word = words.shift
            case word
            when /(-)?(\d{2}):(\d{2})(?::(\d{2}(\.\d+)?))?/
              sign = if $1 then -1 else +1 end
              args['hours'] = sign * $2.to_i
              args['minutes'] = sign * $3.to_i
              args['seconds'] = sign * $4.to_f
            when /\d+/
              n = word.to_i
              units = words.shift
              case units
              when 'day', 'days'
                args['days'] = n
              when 'mon', 'mons'
                args['months'] = n
              when 'year', 'years'
                args['years'] = n
              else
                raise ArgumentError
              end
            else
              raise ArgumentError
            end
          end
        rescue ArgumentError
          raise ArgumentError, "Syntax error in interval: #{s.inspect}"
        end
        PgInterval.new(args)
      end

    end

    # Constructor.
    #
    # [args]
    #   The values of the days, minutes, and so on, as a hash.
    #   Each value is an Integer except for ago, which is a boolean.  
    #
    #   The keys are:
    #   * millennia
    #   * centuries
    #   * decades
    #   * years
    #   * months
    #   * weeks
    #   * days
    #   * hours
    #   * minutes
    #   * seconds
    #
    #   Any integer not specified defaults to 0; any boolean not specified
    #   defaults to false.

    def initialize(args = {})
      args = args.dup
      @values = Hash[*FIELDS.collect do |field|
          [field, args.delete(field) || default(field)]
        end.flatten]
      raise ArgumentError, args.inspect unless args.empty?
    end

    # Convert to Postgres format (ie "1 day 12:00:00")

    def to_s
      s = (to_s_pieces(DATE_FIELDS) + [to_s_time_piece]).compact.join(' ')
      if s == ""
        "0 days"
      else
        s
      end + (ago ? " ago" : "")
    end

    protected

    def parts
      @values.values
    end

    private

    def column_type
      'interval'
    end

    def singularize(units)
      units.gsub(/ia$/, 'ium').gsub(/ies$/, 'y').gsub(/s$/, '')
    end

    def default(field)
      if field == 'ago'
        false
      else
        0
      end
    end

    def to_s_pieces(fields)
      fields.collect do |field|
        value = @values[field]
        if value == 0
          nil
        else
          if value == 1
            "#{value} #{singularize(field)}"
          else
            "#{value} #{field}"
          end
        end
      end
    end

    def to_s_time_piece
      h, m, s = hours, minutes, seconds
      if hours == 0 && minutes == 0 && seconds == 0
        nil
      else
        allNegative = hours <= 0 && minutes <= 0 && seconds <= 0
        allPositive = hours >= 0 && minutes >= 0 && seconds >= 0
        if allNegative || allPositive
          format = "%s%02d:%02d"
          sign = if allNegative then "-" else "" end
          if s != 0
            if s.is_a?(Float)
              format << ":%09.6f"
            else
              format << ":%02d"
            end
          end
          format % [sign, hours.abs, minutes.abs, seconds.abs]
        else
          to_s_pieces(TIME_FIELDS)
        end
      end
    end

  end

end

# Local Variables:
# tab-width: 2
# ruby-indent-level: 2
# indent-tabs-mode: nil
# End:
