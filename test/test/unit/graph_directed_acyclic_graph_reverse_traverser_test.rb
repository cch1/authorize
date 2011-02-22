require 'test_helper'
require 'authorize/graph/directed_acyclic_graph_reverse_traverser'

class GraphDirectedAcyclicGraphReverseTraverserTest < ActiveSupport::TestCase
  include Authorize::Graph

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    DirectedAcyclicGraph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    build_simpsons_geneaology_graph
  end

  test 'reverse traverse DAG' do
    assert_equal Set[@H, @A, @O], DirectedAcyclicGraphReverseTraverser.traverse(@H).to_set
  end

  private
  # http://en.wikipedia.org/wiki/List_of_characters_in_The_Simpsons
  # http://simpsons.wikia.com/wiki/Abraham_Simpson
  def build_simpsons_geneaology_graph
    @g0 = DirectedAcyclicGraph.new
    @O = @g0.vertex("Orville")
    @A = @g0.vertex("Abraham")
    @J = @g0.vertex("Jacqueline")
    @H = @g0.vertex("Homer")
    @M = @g0.vertex("Marge")
    @S = @g0.vertex("Selma")
    @B = @g0.vertex("Bart")
    @L = @g0.vertex("Lisa")
    e0 = @g0.edge(nil, @O, @A, :name => "father")
    e1 = @g0.edge(nil, @A, @H, :name => "father")
    e2 = @g0.edge(nil, @H, @B, :name => "father")
    e3 = @g0.edge(nil, @H, @L, :name => "father")
    e4 = @g0.edge(nil, @J, @M, :name => "mother")
    e5 = @g0.edge(nil, @J, @S, :name => "mother")
    e6 = @g0.edge(nil, @M, @B, :name => "mother")
    e7 = @g0.edge(nil, @M, @L, :name => "mother")
  end
end