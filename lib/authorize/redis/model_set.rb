module Authorize
  module Redis
    # A persistent set of homomorphic Redis-like models
    class ModelSet < Redis::Set
      def initialize(klass)
        super()
        @klass = klass
      end

      [:add, :delete].each do |m|
        define_method(m) {|v| super(v.id)}
      end

      def __getobj__
        super.map{|eid| @klass.load(eid)}.to_set.freeze
      end
    end
  end
end