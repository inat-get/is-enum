# frozen_string_literal: true

module IS; end

class IS::Enum

  include Comparable

  class << self

    include Enumerable

    def [] name_or_order
      case name_or_order
      when String, Symbol
        key = name_or_order.to_sym
        @values[key] || @aliases[key]
      when Integer
        @values.values.find { |v| v.order_no == name_or_order }
      else
        raise ArgumentError, "Invalid value for name or order_no: #{ name_or_order.inspect }", caller_locations
      end
    end

    def each
      return to_enum(__method__) unless block_given?
      @values.values.sort_by { |v| v.order_no }.each { |v| yield v }
    end

    def values
      @values.values.sort_by { |v| v.order_no }
    end

    def aliases
      @aliases
    end

    protected

    def define name, order_no = nil, **attrs
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

    private :new

  end

  attr_reader :order_no, :name, :description

  def initialize order_no, name, description, **attrs
    @order_no = order_no
    @name = name
    @description = description
    attrs.each do |key, value|
      instance_variable_set "@#{ key }", value
    end
  end

  def <=> other
    case other
    when self.class
      self.order_no <=> other.order_no
    when Symbol, String
      self.order_no <=> self.class[other.to_sym].order_no
    when Integer
      self.order_no <=> other
    else
      nil
    end
  end

  def to_sym
    name
  end

  def next
    self.class.values.find { |v| v.order_no > self.order_no }
  end

  def previous
    values = self.class.values.to_a
    index = values.rindex { |v| v.order_no < self.order_no }
    values[index]
  end

end
