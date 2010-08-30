require 'active_support/test_case'
require 'active_record/fixtures'

module Authorize::Graph::Fixtures
  YAML.add_domain_type("hapgoods.com,2010", 'graph') do |type, value|
    process(Authorize::Role.graph, value)
  end

  def create_fixtures(db = Authorize::Redis::Base.db, pathname = Pathname.new(ActiveSupport::TestCase.fixture_path).join('authorize', 'role_graph.yml'))
    db.flushdb
    YAML.load(ERB.new(pathname.read).result)
  end
  module_function :create_fixtures

  def self.process(graph, nodes, parent = nil)
    nodes.each do |node|
      name = node.respond_to?(:keys) ? node.keys.first : node
      children = node.respond_to?(:values) ? node.values.first : []
      key = name_to_key(name)
      vertex = Authorize::Graph::Vertex.exists?(key) ? Authorize::Graph::Vertex.load(key) : graph.vertex(key)
      graph.edge(nil, parent, vertex) if parent
      process(graph, children, vertex) unless children.empty?
    end
  end

  def self.name_to_key(name)
    id = ::Fixtures.identify(name)
    Authorize::Graph::Vertex.subordinate_key(Authorize::Role::VERTICES_ID_PREFIX, id)
  end
end