# frozen_string_literal: true

class PoliciesController < RestController
  include FindResource
  include AuthorizeResource

  before_filter :current_user
  before_filter :find_or_create_root_policy

  def put
    authorize :update

    load_policy perform_automatic_deletion: true, delete_permitted: true, update_permitted: true
  end

  def patch
    authorize :update

    load_policy perform_automatic_deletion: false, delete_permitted: true, update_permitted: true
  end

  def post
    authorize :create

    load_policy perform_automatic_deletion: false, delete_permitted: false, update_permitted: false
  end

  protected

  def load_policy(perform_automatic_deletion:, delete_permitted:, update_permitted:)
    policy_text = request.raw_post

    policy_version = PolicyVersion.new \
      role: current_user, policy: resource, policy_text: policy_text
    policy_version.perform_automatic_deletion = perform_automatic_deletion
    policy_version.delete_permitted = delete_permitted
    policy_version.update_permitted = update_permitted
    policy_version.save
    loader = Loader::Orchestrate.new policy_version
    loader.load

    created_roles = loader.new_roles.select do |role|
      %w[user host].member?(role.kind)
    end.each_with_object({}) do |role, memo|
      credentials = Credentials[role: role] || Credentials.create(role: role)
      memo[role.id] = { id: role.id, api_key: credentials.api_key }
    end

    render json: {
      created_roles: created_roles,
      version: policy_version.version
    }, status: :created
  end

  def find_or_create_root_policy
    Loader::Types.find_or_create_root_policy account
  end
end
