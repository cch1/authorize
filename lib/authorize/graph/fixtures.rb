require 'active_support/test_case'
require 'active_record/fixtures'

module Authorize
  module Graph
    module Fixtures
      YAML.add_domain_type("hapgoods.com,2010", 'graph') do |type, value|
        process(Role.graph, value)
      end

      def create_fixtures(db = Redis::Base.db, pathname = Pathname.new(ActiveSupport::TestCase.fixture_path).join('authorize', 'role_graph.yml'), flush = true)
        db.flushdb if flush
        YAML.load(ERB.new(pathname.read).result)
      end
      module_function :create_fixtures

      def self.process(graph, nodes, parent = nil)
        nodes.each do |node|
          name = node.respond_to?(:keys) ? node.keys.first : node
          children = node.respond_to?(:values) ? node.values.first : []
          key = name_to_key(name)
          vertex = graph.vertex(key)
          graph.edge(nil, parent, vertex) if parent
          process(graph, children, vertex) unless children.empty?
        end
      end

      def self.name_to_key(name)
        ::Fixtures.identify(name).to_s
      end
    end
  end
end