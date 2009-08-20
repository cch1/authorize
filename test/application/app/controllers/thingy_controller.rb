class ThingyController < ApplicationController
  permit 'overlord', :except => :show
  
  def index
    render :nothing => true
  end
  
  def show
    render :text => "I see London, I see France"
  end
end
