require "alog/version"

require 'logger'

module Alog
  class AlogException < StandardError; end

  # allow application to provide which tag should print out
  LogTag = [:global]
  
  # allow application to configure multiple logging
  # log factories configurations
  LogFacts = {}
  
  # multi logger created from
  # LogFacts entry given by application
  GLog = {}

  def add_log_fact(key, conf)
    # add new log fact to global if not defined
    if LogFacts.include?(key)
    else
      LogFacts[key] = conf
    end
  end

  # 
  # class Alogger
  # Inherited from standard library Logger
  # 
  class Alogger < Logger
    def initialize(args)
      @log = Logger.new(*args)
    end

    def log(msg, type = :debug, &block)
      @log.send(type, msg)
    end
  end
  # end class Alogger
  # 

  # 
  # class AloggerObject
  # Mimiking the original Logger object
  # to be used by application but with
  # the conditioning logging logic available
  # to the application instead
  #
  class AOlogger
    attr_reader :logEng
    # Major change on v1.0
    #def initialize(key = :global, logEng = [], active_tag = LogTag)
    def initialize(params = { key: :global, logEng: [], active_tag: LogTag } )
      @myMethods = [:debug, :error, :warn, :warning, :info]
      @defKey = params[:key]
      @logEng = params[:logEng] || []
      @activeTag = params[:active_tag] || []
    end

    def log(msg, ltype = :debug, key = :global, logEng = [], active_tag = [])
      CondLog.call(msg, { key: (key == :global ? key : @defKey), type: ltype, logEng: (logEng == [] ? @logEng : logEng), active_tag: (active_tag == [] ? @activeTag : active_tag) })
    end

    def activate_tag(tag, &block)
      @activeTag << tag
      if block
        block.call 
        @activeTag.delete(tag)
      end
    end

    def deactivate_tag(tag)
      @activeTag.delete(tag)
    end

    def ext_error(ex)
      if ex.is_a?(Exception)
        error(ex.message)
        error(ex.backtrace.join("\n"))
      else
        error(ex)
      end
    end

    def no_active_tags
      @activeTag = []
    end

    def show_all_tags
      @activeTag << :all
    end

    def selected_tags_only
      @activeTag.delete(:all)
    end

    def method_missing(mtd, *args, &block)
      if @myMethods.include?(mtd)
        params = {}
        pa = args[1]
        params[:key] = @defKey
        params[:logEng] = @logEng
        params[:active_tag] = @activeTag
        # TODO cases here may not be extensive to 
        # the original Logger supported.
        case mtd
        when :debug
          params[:type] = :debug
          CondLog.call(args[0], params, &block)
        when :error
          params[:type] = :error
          CondLog.call(args[0], params, &block)
        when :warn, :warning
          params[:type] = :warn
          CondLog.call(args[0], params, &block)
        when :info
          params[:type] = :info
          CondLog.call(args[0], params, &block)
        end
        
      else
        super
      end
    end
  end
  # 
  # end class AloggerObject
  # 

  def show_all_tags
    LogTag << :all
  end

  def selected_tags_only
    LogTag.delete(:all)
  end

  # 
  # Provide a block construct that can set values consistantly for multiple clog() call
  # TODO How to make this thread safe?
  # 
  def l(key = :global, params = { type: :debug, logEng: [] } ,&block)
    # this construct try to make the variable private to the block
    # Still not sure will error condition exist for multi threaded application
    b = Proc.new do |key, params, &block|
      @lKey = key 
      @lType = params[:type]
      @llEng = params[:logEng]
      if block
        block.call
      end
    end
    b.call(key, params, &block)
  end

  def clog_context
    { key: @lKey, type: @lType, engine: @llEng }
  end

  #
  # Module level clog() method
  # Meant to be called by application INSIDE the l()'s block
  # 
  def clog(msg, ltype = :debug, key = :global, logEng = [])
    log(msg, { type: @lType != ltype ? ltype : @lType, 
               key: (key != @lKey ? key : @lKey),
               logEng: @llEng  })
  end
  #
  # end of module level clob()
  # 

  # 
  # Actual logic of detecting a tag should be activated and on which logger should it written to
  # 
  CondLog = Proc.new do |msg, params = {}, &block|
    key = params[:key] || :global
    type = params[:type] || :debug
    activeTag = params[:active_tag] || LogTag
    #if defined?(:LogTag) and LogTag.is_a?(Array) and (LogTag.include?(key) or LogTag.include?(:all)) or type == :error
    if (activeTag.include?(key) or activeTag.include?(:all)) or type == :error
      logEng = params[:logEng]
      if logEng == nil or (logEng != nil and logEng.empty?)
        logEng = (LogFacts.length > 0 ? [LogFacts.keys[0]] : [:default])
      end
      
      logEng = [logEng] if not logEng.is_a?(Array)

      # allow written to multiple logger
      logEng.each do |e|
        
        if GLog[e] == nil

          lp = LogFacts[e]
          if lp == nil
            # default if empty
            lp = [STDOUT]
          end

          # ensure the same configuration only created a logger object once
          GLog[e] = Alogger.new(lp)

        end
       
        caller.each do |c|
          if c =~ /alog.rb/
          else
            @cal = c
            break
          end
        end

        #GLog[e].log("#{caller.length > 4 ? "[#{File.basename(caller[4])}]" : ""} [#{key}] #{msg}", type, &block)
        GLog[e].log("[#{File.basename(@cal)}] [#{key}] #{msg}", type, &block)
      end
      
    end
    
  end
  # end CondLog() proc
  # 

  # provide module level method to write to the logger object
  def log(msg, params = { }, &block)
    CondLog.call(msg, params, &block)
  end
  # end module level log()

end
