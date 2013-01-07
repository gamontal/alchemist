module Alchemist
  class NumericConversion
    include Comparable

    def per
      Alchemist::CompoundNumericConversion.new(self)
    end
    alias_method :p, :per

    def to(type = nil)
      unless type
        self
      else
        send(type)
      end
    end
    alias_method :as, :to

    def base(unit_type)
      conversion_base = conversion_base_for(unit_type)

      if(conversion_base.is_a?(Array))
        exponent * conversion_base[0].call(value)
      else
        exponent * value * conversion_base
      end
    end

    def unit_name
      @unit_name
    end

    def to_s
      value.to_s
    end

    def exponent
      @exponent
    end

    def value
      @value
    end

    def to_f
      @value
    end

    def ==(other)
      (self <=> other) == 0
    end

    def <=>(other)
      (self.to_f * exponent).to_f <=> other.to(unit_name).to_f
    end

    private
    def initialize value, unit_name, exponent = 1.0
      @value = value.to_f
      @unit_name = unit_name
      @exponent = exponent
    end

    def conversion_base_for unit_type
      Alchemist.conversion_table[unit_type][unit_name]
    end

    def method_missing unit_name, *args, &block
      exponent, unit_name = Alchemist.parse_prefix(unit_name)

      if Conversions[ unit_name ]
        types = Conversions[ self.unit_name ] & Conversions[ unit_name ]
        if types[0] # assume first type
          if(Alchemist.conversion_table[types[0]][unit_name].is_a?(Array))
            Alchemist.conversion_table[types[0]][unit_name][1].call(base(types[0]))
          else
            NumericConversion.new(base(types[0]) / (exponent * Alchemist.conversion_table[types[0]][unit_name]), unit_name)
          end
        else
          raise Exception, "Incompatible Types"
        end
      else
        if args[0] && args[0].is_a?(NumericConversion) && Alchemist.operator_actions[unit_name]
          t1 = Conversions[ self.unit_name ][0]
          t2 = Conversions[ args[0].unit_name ][0]
          Alchemist.operator_actions[unit_name].each do |s1, s2, new_type|
            if t1 == s1 && t2 == s2
              return (value * args[0].to_f).send(new_type)
            end
          end
        end
        if unit_name == :*
          if args[0].is_a?(Numeric)
            @value *= args[0]
            return self
          else
            raise Exception, "Incompatible Types"
          end
        end
        if unit_name == :/ && args[0].is_a?(NumericConversion)
          raise Exception, "Incompatible Types" unless (Conversions[ self.unit_name ] & Conversions[ args[0].unit_name ]).length > 0
        end
        args.map!{|a| a.is_a?(NumericConversion) ? a.send(self.unit_name).to_f / exponent : a }
        @value = value.send( unit_name, *args, &block )


        unit_name == :/ ? value : self
      end
    end
  end

end