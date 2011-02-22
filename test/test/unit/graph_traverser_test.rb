require 'test_helper'
require 'authorize/graph/traverser'

class GraphTraverserTest < ActiveSupport::TestCase
  include Authorize::Graph

  def setup
    Authorize::Redis::String.index.clear # Clear the cache
    Authorize::Redis::Set.index.clear
    Authorize::Redis::Hash.index.clear
    Authorize::Graph::Graph.index.clear
    Authorize::Graph::Vertex.index.clear
    Authorize::Graph::Edge.index.clear
    create_interstate_graph
  end

  test 'traverse graph' do
    assert_equal Set[@cho, @ric, @spr, @dlg, @cnv, @str, @stn, @roa], Traverser.traverse(@dlg).to_set
    assert_equal 8, Traverser.traverse(@dlg).count
    assert_equal 8, Traverser.traverse(@dlg).each{|x|}
  end

  def create_interstate_graph
    @g0 = Authorize::Graph::UndirectedGraph.new("Highways")
    @cho = @g0.vertex("Charlottesville")
    @ric = @g0.vertex("Richmond")
    @spr = @g0.vertex("Springfield")
    @dlg = @g0.vertex("Dunn_Loring")
    @cnv = @g0.vertex("Centreville")
    @str = @g0.vertex("Strasburg")
    @stn = @g0.vertex("Staunton")
    @roa = @g0.vertex("Roanoke")
    e0a = @g0.join(nil, @stn, @cho, :name => "I64", :cost => 95)
    e0b = @g0.join(nil, @cho, @ric, :name => "I64", :cost => 100)
    e1 = @g0.join(nil, @ric, @spr, :name => "I95", :cost => 85)
    e2 = @g0.join(nil, @spr, @dlg, :name => "I495", :cost => 20)
    e3a = @g0.join(nil, @dlg, @cnv, :name => "I66", :cost => 40)
    e3b = @g0.join(nil, @cnv, @str, :name => "I66", :cost => 120)
    e4 = @g0.join(nil, @str, @stn, :name => "I81", :cost => 130)
    e5 = @g0.join(nil, @stn, @roa, :name => "I81", :cost => 125)
    e5 = @g0.join(nil, @cho, @cnv, :name => "US29", :cost => 200)
  end
end