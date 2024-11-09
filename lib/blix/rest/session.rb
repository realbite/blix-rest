module Blix::Rest

  module Session
    #----------------------------------------------------------------------------
    #
    #  manage the session and authorization
    #
    #----------------------------------------------------------------------------

    DAY = 24 * 60 * 60
    MIN = 60
    SESSION_NAME = 'blix'

    SESSION_OPTS = {
      #:secure=>true,
      :http => false,
      :samesite => :lax,
      :path => Blix::Rest.full_path('/'),
      :expire_secs => 30 * MIN,       # 30 mins
      :cleanup_every_secs => 5 * 60   # 5 minutes
      #:max_age => nil # session cookie
    }.freeze


    def session_manager
      self.class.get_session_manager
    end

    def session_skip_update
      @__session_id = nil
    end


    def session_name
      self.class.get_session_name
    end

    def session_opts
      self.class.get_session_opts
    end

    def session
      @__session
    end

    def csrf_token
      @__session['csrf'] ||= SecureRandom.hex(32)
    end

    def reset_session
      raise 'login_session missing' unless @__session && @__session_id
      session_manager.delete_session(@__session_id)
      @__session_id = refresh_session_id(session_name, session_opts)
      @__session['csrf'] = SecureRandom.hex(32)
      session_manager.store_session(@__session_id, @__session)
    end

    # get a session id and use this to retrieve the session information - if any.
    #
    def session_before(opts)
      @__session = {}

      # do not set session on pages. that will be cached.
      unless opts[:nosession] || opts[:cache]
        @__session_id = get_session_id(session_name, session_opts)
        @__session =
          begin
            session_manager.get_session(@__session_id)
          rescue SessionExpiredError
            @__session_id = refresh_session_id(session_name, session_opts)
            session_manager.get_session(@__session_id)
          end
      end

      if opts[:csrf] && (ENV['RACK_ENV']!='test')
        if env["HTTP_X_CSRF_TOKEN"] != csrf_token 
          send_error("error [0100]")
        end
      end

    end

    # save the session hash before we go.
    def session_after
      session_manager.store_session(@__session_id, @__session) if @__session_id
    end

    private

    def self.included(mod)
      mod.extend Session::ClassMethods
    end

    module ClassMethods

      def session_name(name)
        @_sess_name = name.to_s
      end

      def session_opts(opts)
        @_sess_custom_opts = opts
      end

      def session_manager(man)
        raise ArgumentError, "incompatible session store" unless man.respond_to?(:get_session)
        raise ArgumentError, "incompatible session store" unless man.respond_to?(:store_session)
        raise ArgumentError, "incompatible session store" unless man.respond_to?(:delete_session)
        @_sess_manager= man
      end

      def get_session_name
        @_sess_name ||= begin
          if superclass.respond_to?(:get_session_name)
            superclass.get_session_name
          else
            SESSION_NAME
          end
        end
      end

      def get_session_opts
        @_session_opts ||= begin
          if superclass.respond_to?(:get_session_opts)
            superclass.get_session_opts.merge(@_sess_custom_opts || {})
          else
            SESSION_OPTS.merge(@_sess_custom_opts || {})
          end
        end
      end

      def get_session_manager
        @_sess_manager ||= begin
          if superclass.respond_to?(:get_session_manager)
            superclass.get_session_manager
          else
            Blix::RedisStore.new(get_session_opts)
          end
        end
      end

    end # ClassMethods
  end # Session
end  # Blix::Rest
