module HasProviders
  extend ActiveSupport::Concern

  protected

  def lookup_provider base_module
    _, provider_name = action_name.split('_', 2)
    base_module.const_get(provider_name.underscore.camelize)
  end
end
