module Provider
  module Authentication
    Kubernetes = Struct.new(:role, :request) do

      def perform_authentication
        role_ids = collect_role_ids
        unless role_ids.member?(role.role_id)
          Rails.logger.debug "Role #{role.role_id.inspect} not found in Kubernetes object list #{role_ids.inspect}"
          raise Exceptions::Unauthorized
        end
        true
      end

      protected

      def account
        role.account
      end

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

      def collect_role_ids
        [ pod_id, replicaset_id, statefulset_id, deployment_id ].compact.map do |name|
          name.unshift pod.metadata.namespace
          name.unshift "kubernetes"
          [ account, "host", name.join("/") ].join(":")
        end
      end

      # Construct a replicaset id from the pod pod.metadata.ownerReferences.ReplicaSet,
      def replicaset_id
        def valid?
          !pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.empty?
        end

        return nil unless valid?

        pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.map do |ref|
          [ "replicaset", ref.name ]
        end
      end

      # Construct a deployment id from the pod pod.metadata.ownerReferences.ReplicaSet,
      # where the replicaset name is "#{name}-#{replicaset.metadata.labels['pod-template-hash']"
      def deployment_id
        def valid?
          pod.metadata.labels && 
            ( template_hash = pod.metadata.labels['pod-template-hash'] ) &&
            pod.metadata.ownerReferences &&
            pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.find{|ref| ref.name =~ /-#{template_hash}$/}
        end

        return nil unless valid?

        template_hash = pod.metadata.labels['pod-template-hash']
        names = pod.metadata.ownerReferences.select{|ref| ref.kind == "ReplicaSet"}.map{|ref| ref.name =~ /(.*)-#{template_hash}$/; $1}
        names.map do |name|
          [ "deployment", name ]
        end
      end

      # Construct a stateful set id from the pod "pod.metadata.created_by.reference".
      def statefulset_id
        def valid?
          pod.metadata.annotations &&
            ( created_by = pod.metadata.annotations['kubernetes.io/created-by'] ) &&
            created_by['reference'] &&
            created_by['reference']['kind'] &&
            created_by['reference']['kind'] == 'StatefulSet'
        end

        return nil unless valid?

        [ "statefulset", created_by['reference']['name'] ]
      end

      # Select all Pods that match the request ip.
      def pod_id
        [ "pod", pod.metadata.name ]
      end

      def pod
        @pod ||= find_pod
      end

      def find_pod
        pods = kube_client.get_pods.select do |pod|
          pod.status.podIP == request_ip
        end
        raise Exceptions::Unauthorized, "No pod matches request IP #{request_ip}" if pods.empty?
        raise Exceptions::Unauthorized, "Multiple pods match request IP #{request_ip}" if pods.size > 1
        pods.first
      end

      def kube_client
        build_kubectl_client
      end

      # Different constructor parameters are required to examine stateful sets.
      def kube_client_stateful_sets
        build_kubectl_client api: 'apis/apps', version: 'v1beta1'
      end

      def build_kubectl_client api: "api", version: "v1"
        Kubeclient::Client.new [ "http://localhost:8080", api ].join('/'), version
      end
    end
  end
end
