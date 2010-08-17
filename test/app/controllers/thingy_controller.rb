class ThingyController < ApplicationController
  permit({:all => Widget}, :except => :show)

  def index
    render :nothing => true
  end

  def show
    render :text => "I see London, I see France"
  end
end