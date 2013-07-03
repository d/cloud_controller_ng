module VCAP::CloudController::RestController
  module Routes
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def define_route(verb, path, method = nil, opts = {}, &blk)
        klass = self
        controller.send(verb, path, opts) do |*args|
          logger.debug "dispatch #{klass} #{verb} #{path}"
          api = klass.new(@config, logger, env, request.params, request.body, self)
          if method
            api.dispatch(method, *args)
          else
            blk.yield(api, *args)
          end
        end
      end

      def get(path, method=nil, &blk)
        define_route("get", path, method, {}, &blk)
      end

      def delete(path, method=nil, &blk)
        define_route("delete", path, method, {}, &blk)
      end

      def post(path, method=nil, &blk)
        define_route("post", path, method, {consumes: :json}, &blk)
      end

      def put(path, method=nil, &blk)
        define_route("put", path, method, {consumes: :json}, &blk)
      end

      # normal PUT that should not be restricted to json content type
      def form_put(path, method=nil, &blk)
        define_route("put", path, method, {}, &blk)
      end

      def define_routes
        define_standard_routes
        define_to_many_routes
      end

      private

      def define_standard_routes
        post   path,    :create
        get    path,    :enumerate
        get    path_id, :read
        put    path_id, :update
        delete path_id, :delete
      end

      def define_to_many_routes
        to_many_relationships.each do |name, attr|
          get "#{path_id}/#{name}" do |api, id|
            api.dispatch(:enumerate_related, id, name)
          end

          form_put "#{path_id}/#{name}/:other_id" do |api, id, other_id|
            api.dispatch(:add_related, id, name, other_id)
          end

          delete "#{path_id}/#{name}/:other_id" do |api, id, other_id|
            api.dispatch(:remove_related, id, name, other_id)
          end
        end
      end

      def controller
        VCAP::CloudController::Controller
      end
    end
  end
end
