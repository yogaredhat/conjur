require 'kubeclient'

module Provider
  module Authentication
    # Determines whether a Pod is contained within various Kubernetes workload types.
    # For example, given a Pod, determine whether it's part of a ReplicaSet, Deployment, or StatefulSet.
    module KubernetesWorkloadMatcher
      Pod = Struct.new(:name) do
        def include? pod
          pod.metadata.name == self.name
        end
      end

      Replicaset = Struct.new(:name) do
        def include? pod
          return false unless pod.metadata.ownerReferences
          pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.find{|ref| ref.name == self.name}
        end
      end

      Deployment = Struct.new(:name) do
        def include? pod
          return false unless pod.metadata.labels && 
              pod.metadata.labels['pod-template-hash'] &&
              pod.metadata.ownerReferences

          template_hash = pod.metadata.labels['pod-template-hash']
          pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.find{|ref| ref.name == "#{self.name}-#{template_hash}"}
        end
      end

      Statefulset = Struct.new(:name) do
        def include? pod
          return false unless pod.metadata.annotations &&
            pod.metadata.annotations['kubernetes.io/created-by']
          annotations = JSON.parse(pod.metadata.annotations['kubernetes.io/created-by'])
          annotations['reference'] &&
            annotations['reference']['kind'] &&
            annotations['reference']['kind'] == 'StatefulSet' &&
            annotations['reference']['name'] == self.name
        end
      end

      class << self
        def matcher type, name
          const_get(type.classify).new(name)
        end
      end
    end

    Kubernetes = Struct.new(:role, :request) do

      KUBERNETES_SERVICEACCOUNT_DIR = '/var/run/secrets/kubernetes.io/serviceaccount'

      class << self
        # Builds a Kubeclient::Client for an API path and version.
        def kube_client api: "api", version: "v1"
          raise "Kubernetes serviceaccount dir #{KUBERNETES_SERVICEACCOUNT_DIR} does not exist" unless File.exists?(KUBERNETES_SERVICEACCOUNT_DIR)
          %w(KUBERNETES_SERVICE_HOST KUBERNETES_SERVICE_PORT).each do |var|
            raise "Expected environment variable #{var} is not set" unless ENV[var]
          end

          url = "https://#{ENV['KUBERNETES_SERVICE_HOST']}:#{ENV['KUBERNETES_SERVICE_PORT']}"
          token_args = {
            auth_options: {
              bearer_token_file: File.join(KUBERNETES_SERVICEACCOUNT_DIR, 'token')
            }
          }

          ssl_args = {
            ssl_options: {
              ca_file: File.join(KUBERNETES_SERVICEACCOUNT_DIR, 'ca.crt'),
              verify_ssl: OpenSSL::SSL::VERIFY_PEER
            }
          }
          $stderr.puts "Kubernetes.kube_client: FIXME"
          url = 'http://localhost:8080'
          Kubeclient::Client.new [ url, api ].join('/'), version, ssl_args.merge(token_args)
        end

        # Finds the pod which matches a request IP.
        def pod_from_ip request_ip
          # Use the fieldSelector but double-check in Ruby code.
          kube_client.get_pods(fieldSelector: "status.podIP=#{request_ip}").find do |pod|
            pod.status.podIP == request_ip
          end
        end
      end

      def perform_authentication
        unless pod
          Rails.logger.debug "No pod found for request IP #{request_ip.inspect}"
          raise Exceptions::Unauthorized
        end

        workload_namespace = resource.annotation('kubernetes/namespace') || 'default'
        unless pod.metadata.namespace == workload_namespace
          Rails.logger.debug "Pod #{pod.metadata.name} namespace #{pod.metadata.namespace.inspect} does not match expectation #{workload_namespace.inspect}"
          raise Exceptions::Unauthorized
        end

        workload_name   = resource.annotation('kubernetes/workload-name') || resource.id.split('/')[-1]
        workload_type = resource.annotation('kubernetes/workload-type') || 'deployment'
        matcher = KubernetesWorkloadMatcher.matcher workload_type, workload_name

        unless matcher.include? pod
          Rails.logger.debug "Pod #{pod.metadata.name} is not part of #{workload_type} #{workload_id.inspect}"
          raise Exceptions::Unauthorized
        end

        true
      end

      protected

      def rack_request
        @rack_request ||= Rack::Request.new(request.env)
      end

      def request_ip
        # In test & development, allow override of the request IP
        ip = if %w(test development).member?(Rails.env)
          request.params[:request_ip]
        end
        ip ||= rack_request.ip
      end

      def resource
        @resource ||= role.resource
      end

      def pod
        @pod ||= self.class.pod_from_ip request_ip
      end
    end
  end
end
