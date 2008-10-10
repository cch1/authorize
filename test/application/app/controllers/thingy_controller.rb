class ThingyController < ApplicationController
  permit 'overlord'
  
  def index
    render :nothing => true
  end
end
