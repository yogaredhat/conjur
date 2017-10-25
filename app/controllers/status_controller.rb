class StatusController < ApplicationController
  def index
    @version = ENV['CONJUR_VERSION']
    render 'index'
  end
end
