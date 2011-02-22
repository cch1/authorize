module Authorize
  module Redis
    # A Factory is designed to help build relevant test fixtures in the context of a test.  In order to preserve a high
    # signal-to-noise ratio in the test, a factory needs to *concisely* build fixtures even at the expense of supporting
    # cool features.  As a result, index management and references to other values are the responsibility of the programmer. 
    class Factory
      attr_reader :db

      def self.build(ns = nil, &block)
        self.new.tap do |f|
          f.namespace(ns, &block) if ns
        end
      end

      def initialize(db = Base.db)
        @namespace = nil
        @db = db
      end

      def namespace(name, &block)
        @old_namespace, @namespace = @namespace, subordinate_key(name)
        if block_given?
          self.instance_eval(&block)
          @namespace = @old_namespace
        else
          self
        end        
      end

      def string(name, value = "")
        key = subordinate_key(name)
        db.set(key, value)
        namespace(name){yield} if block_given?
        Redis::String.load(key)
      end

      def hash(name, value = {})
        key = subordinate_key(name)
        value.each {|k, v| db.hset(key, k, v)}
        namespace(name){yield} if block_given?
        Redis::Hash.load(key)
      end

      def set(name, value = ::Set[])
        key = subordinate_key(name)
        value.each {|v| db.sadd(key, v)}
        namespace(name){yield} if block_given?
        Redis::Set.load(key)
      end
      
      def array(name, value = [])
        key = subordinate_key(name)
        value.each {|v| db.rpush(key, v)}
        namespace(name){yield} if block_given?
        Redis::Array.load(key)
      end

      private
      def subordinate_key(key)
        [@namespace, key].compact.map(&:to_s).join('::')
      end
    end
  end
end