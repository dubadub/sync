module Sync
  module Model

    def self.enabled?
      Thread.current["model_sync_enabled"]
    end

    def self.context
      Thread.current["model_sync_context"]
    end

    def self.enable!(context = nil)
      Thread.current["model_sync_enabled"] = true
      Thread.current["model_sync_context"] = context
    end

    def self.disable!
      Thread.current["model_sync_enabled"] = false
      Thread.current["model_sync_context"] = nil
    end

    def self.enable(context = nil)
      enable!(context)
      yield
    ensure
      disable!
    end

    module ClassMethods
      attr_accessor :sync_scope

      def sync(*actions)
        include Sync::Actions
        include ModelActions
        if actions.last.is_a? Hash
          @sync_scope = actions.last.fetch :scope
        end
        actions = [:create, :update, :destroy] if actions.include? :all
        actions.flatten!

        if actions.include? :create
          after_create :publish_sync_create, :on => :create#, :if => lamda { Sync::Model.enabled? }
        end
        if actions.include? :update
          after_update :publish_sync_update, :on => :update#, :if => lamda { Sync::Model.enabled? }
        end
        if actions.include? :destroy
          after_destroy :publish_sync_destroy, :on => :destroy#, :if => lamda { Sync::Model.enabled? }
        end
      end
    end

    module ModelActions
      def sync_scope
        return nil unless self.class.sync_scope
        send self.class.sync_scope
      end

      def sync_render_context
        Sync::Model.context || super
      end

      def publish_sync_create
        p "-----------publish_sync_create"
        p Sync.config
        # sync_new self, :scope => sync_scope
        # sync_update sync_scope.reload if sync_scope
      end

      def publish_sync_update
        p "-----------publish_sync_update"
        p self.id
        uri = URI("http://call.gettable.dev:3000/bookings/25243/bumper")
        p uri
        req = Net::HTTP::Put.new(uri.request_uri)

        req["Content-Length"] = '0'
        req["Content-Type"] = 'text/plain;charset=UTF-8'

        res = Net::HTTP.start(uri.host, uri.port) do
          |http| http.request(req)
        end

        p res
        # if sync_scope
        #   sync_update [self, sync_scope.reload]
        # else
        #   sync_update self
        # end
      end

      def publish_sync_destroy
        p "-----------publish_sync_destroy"
        p Sync.config
        # sync_destroy self
        # sync_update sync_scope.reload if sync_scope
      end
    end
  end
end
