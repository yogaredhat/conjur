#shared_context "VCR Basic" do
#  require 'webmock/rspec'
#  RSpec.configure do |config|
#    config.before(:each) do
#      binding.pry
#     WebMock.reset!
#     WebMock.disable_net_connect!
#    end
#  end
#end
