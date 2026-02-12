# frozen_string_literal: true

require 'set'

module IS; end

# @note Thread safety
#
#   Enum definition ({.define}) and finalization ({.finalize!}) are
#   thread-safe. Lookup operations are thread-safe after definition.
#
# @note Class variables
#
#   Uses class variables ( +@@enums+, +@@mutex+ ) shared across inheritance
#   hierarchy. All enum classes register in global +@@enums+ for {.parse}.
#
# @note Custom attributes
#
#   Additional attributes passed to {.define} are stored in `@attrs`.
#   Subclasses may access this hash directly to implement custom properties.
#
#     class Status < IS::Enum
#       define :error, 1, http_code: 500, retryable: false
#
#       def http_code
#         @attrs[:http_code]
#       end
#
#       def retryable?
#         @attrs[:retryable]
#       end
#     end
class IS::Enum

  include Comparable

  class << self

    include Enumerable

    # @group Conversion

    # In specific enum class: get enum value by name; in {IS::Enum} itself: parse string like "Class.name" to enum value.
    #
    # @param source [String] the string to parse
    # @return [IS::Enum] the enum value
    # @raise [ArgumentError] if source is not a String or value not found
    # @note Security consideration
    #   Converts strings to Symbols internally. Do not use with untrusted
    #   user input to avoid memory exhaustion from symbol creation.
    def parse source
      raise ArgumentError, "Invalid source for parsing: #{ source.inspect }", caller_locations unless source.is_a?(String)
      if self == IS::Enum
        parts = source.split '.'
        raise ArgumentError, "Parsing error from #{ source.inspect }", caller_locations unless parts.is_a?(Array) && parts.size == 2
        cls = @@enums[parts[0]]
        raise ArgumentError, "Enum class not found: #{ parts[0] }", caller_locations unless cls
        val = cls[parts[1].to_sym]
        raise ArgumentError, "#{ cls.name } value not found: #{ parts[1] }", caller_locations unless val
        return val
      else
        val = self[source.to_sym]
        raise ArgumentError, "#{ self.name } value not found: #{ source }", caller_locations unless val
        return val
      end
    end

    # Strict lookup by name. Raises if not found.
    # See {.[]} for lenient lookup
    #
    # @param name [Symbol]
    # @return [IS::Enum]
    # @raise [ArgumentError] if name is not a Symbol or value not found
    def of name
      raise ArgumentError, "Invalid name of #{ self }: #{ name.inspect }" unless name.is_a?(Symbol)
      val = @values[name] || @aliases[name]
      raise ArgumentError, "Invalid name of #{ self }: #{ name }" unless val
      return val
    end

    # Converts various types to enum values.
    #
    # @param [IS::Enum, nil, Range, Set, Enumerable, Symbol, String, Integer] value
    # @return [IS::Enum, nil, Range<IS::Enum>, Set<IS::Enum>, Array<IS::Enum>]
    # @example Convert range
    #   MyEnum.from(:alpha..:gamma)  # => range of enum values
    # @example Convert array
    #   MyEnum.from([:alpha, :beta]) # => [MyEnum.alpha, MyEnum.beta]
    def from value
      case value
      when nil
        nil
      when self
        value
      when Range
        Range::new from(value.begin), from(value.end), value.exclude_end?
      when Set
        Set[*value.map { |v| from(v) }]
      when Enumerable
        value.map { |v| from(v) }
      else
        self[value] || raise ArgumentError, "Invalid value of #{ self }: #{ value.inspect }", caller_locations
      end
    end

    # @endgroup

    # @group Collection

    # Lookup by name or order number. Returns nil if not found.
    # See {.of} for strict lookup that raises on missing value
    #
    # @param name_or_order [String, Symbol, Integer]
    # @return [IS::Enum, nil]
    def [](name_or_order)
      case name_or_order
      when String, Symbol
        key = name_or_order.to_sym
        @values[key] || @aliases[key]
      when Integer
        @values.values.find { |v| v.order_no == name_or_order }
      else
        raise ArgumentError, "Invalid value for name or order_no: #{name_or_order.inspect}", caller_locations
      end
    end

    # @return [Enumerator, self]
    def each
      return to_enum(__method__) unless block_given?
      @values.values.sort_by { |v| v.order_no }.each { |v| yield v }
      self
    end

    # @return [Array<IS::Enum>]
    def values
      @sorted ||= @values.values.sort_by { |v| v.order_no }
    end

    # @return [Hash<Symbol, IS::Enum>] hash of alias names to target values
    def aliases
      @aliases
    end

    # @return [IS::Enum, nil] last value by order_no, or nil if empty
    def last
      values.last
    end

    # @return [IS::Enum, nil] first value by order_no, or nil if empty
    def first
      values.first
    end

    # @return [Range<IS::Enum>] range from first to last value
    def to_range
      (first .. last)
    end

    # @return [Hash<Symbol => IS::Enum>] hash of all names and aliases
    # @note Both canonical names and aliases are included. To distinguish,
    #   check {.aliases} for alias keys.
    def to_h
      result = {}
      result.merge! @values
      result.merge! @aliases
    end

    # @endgroup

    protected

    # @group DSL

    # Defines new enum value or alias.
    #
    # @param name [Symbol, String] name of the value
    # @param order_no [Integer, nil] explicit order number (auto-generated if nil)
    # @param attrs [Hash] additional attributes
    # @option attrs [IS::Enum, Symbol, String, nil] :alias create alias to existing value
    # @option attrs [String, nil] :description description of the value
    # @return [IS::Enum] defined value (or aliased value for alias)
    # @raise [ArgumentError] on duplicate name, invalid alias, or invalid order_no
    #
    # @example Define values
    #   class Status < IS::Enum
    #     define :pending, 1, description: "Waiting for processing"
    #     define :active, 2
    #     define :archived, alias: :active
    #   end    
    def define name, order_no = nil, **attrs
      @mutex ||= Thread::Mutex::new
      @mutex.synchronize do
        @sorted = nil
        @values ||= {}
        @aliases ||= {}
        case name
        when String
          name = name.to_sym
        when Symbol
          # do nothing
        else
          raise ArgumentError, "Invalid name: #{ name.inspect }", caller_locations
        end
        raise ArgumentError, "Duplicate value name: #{ name.inspect }", caller_locations if @values.has_key?(name) || @aliases.has_key?(name)
        als = attrs.delete :alias
        case als
        when self
          @aliases[name] = als
          define_singleton_method name do
            als
          end
          return als
        when Symbol, String
          als = als.to_sym
          als_value = @values[als] || @aliases[als]
          raise ArgumentError, "Invalid alias #{ als.inspect }: value not found", caller_locations unless als_value
          @aliases[name] = als_value
          define_singleton_method name do
            als_value
          end
          return als_value
        when nil
          # do nothing
        else
          raise ArgumentError, "Invalid alias value: #{ als.inspect }", caller_locations
        end
        case order_no
        when Integer
          # do nothing
        when nil
          order_no = (@values.values.map(&:order_no).max || 0) + 1
        else
          raise ArgumentError, "Invalid order_no value: #{ order_no.inspect }", caller_locations
        end
        description = attrs.delete :description
        raise ArgumentError, "Invalid description value: #{ description.inspect }", caller_locations unless description.nil? || description.is_a?(String)
        value = new(order_no, name, description, **attrs).freeze
        @values[name] = value
        define_singleton_method name do 
          value
        end
        value
      end
    end

    # Freezes internal structures, preventing further modifications.
    # After calling, {.define} will raise +RuntimeError+.
    #
    # @return [void]
    def finalize!
      @mutex ||= Thread::Mutex::new
      @mutex.synchronize do
        @values.freeze
        @aliases.freeze
      end
    end

    # @endgroup

    # @private
    def inherited subclass
      @@mutex ||= Thread::Mutex::new
      @@mutex.synchronize do
        @@enums ||= {}
        @@enums[subclass.name] = subclass
      end
    end

    private :new

  end

  # Order No for sorting and comparison
  # @note Non-unique order numbers
  #   Multiple values may be defined with the same `order_no`. This affects
  #   sorting order (undefined when equal) and comparison behavior.
  #   See {#<=>} for comparison semantics.
  # @return [Integer]
  attr_reader :order_no

  # @return [Symbol] value name
  attr_reader :name

  # @return [String, nil] optional value description
  attr_reader :description

  # @private
  def initialize order_no, name, description, **attrs
    @order_no = order_no
    @name = name
    @description = description
    @attrs = attrs
  end

  # @group Ordering

  # Returns +1+ if +self > other+; +0+ if +self == other+; +-1+ if +self < other+. +nil+ if other is not same type.
  #
  # @see Comparable
  # @return [Integer, nil]
  # @note Comparison semantics
  #   `==` and `<=>` compare by `order_no`, while `eql?` compares object identity.
  #   Multiple values may share the same `order_no`; they compare as equal
  #   but are distinct objects.
  #
  #     class Alpha < IS::Enum
  #       define :alpha, 10
  #       define :beta, 20
  #       define :bi, 20
  #       define :Gamma, 30
  #       define :g_letter, alias: :Gamma
  #     end
  #     Alpha.beta == Alpha.bi           # => true (same order_no: 20)
  #     Alpha.beta.eql?(Alpha.bi)        # => false (different objects)
  #     Alpha.Gamma.eql?(Alpha.g_letter) # => true (alias is same object)
  def <=> other
    case other
    when self.class
      self.order_no <=> other.order_no
    when Symbol, String
      self.order_no <=> self.class[other.to_sym]&.order_no
    when Integer
      self.order_no <=> other
    else
      nil
    end
  end

  # Returns the next value by order_no, or nil if last.
  #
  # @return [IS::Enum, nil]
  def succ
    self.class.values.find { |v| v.order_no > self.order_no }
  end

  # @endgroup

  # @group Conversion

  # @return [Symbol] name as symbol
  def to_sym
    name
  end

  # @return [String] name as string
  def to_s
    name.to_s
  end

  # @return [String] detailed inspection string with class, name, order_no and attributes
  def inspect
    data = [ "#{ self.class }.#{ self.name }", "order_no=#{ @order_no }" ]
    data << "description=#{ @description.inspect }" if @description
    @attrs.each do |key, value|
      data << "#{ key }=#{ value.inspect }"
    end
    "[enum #{ data.join(' ') }]"
  end

  # @endgroup

end
