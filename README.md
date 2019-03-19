# Alog

Alog (Advanced/Antrapol Logging) is an attempt to tackle the logging issue that is too verbose. 

Logging is better to be verbose but when working on large project, the development is evolution type of progress instead of revolution. Hence the logging output tends to be increasing over the time of development. Those logging generated during the early stage of the development may not be siginificant in later development work. 

In other framework there is conditional logging like #IFDEF in C to ignore logging if a key is not defined. 

This conditional logging however is not related to the log level (DEBUG, ERROR etc) as defined by the log engine.

Alog is meant to be allow developer to group the logging under a meaningful tag and if the tag is not defined, the log is skipped therefore removing the log entirely out from the view of the developer and left only the current focusing development work's log.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alog'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install alog

## Usage

First is to include the alog library
```ruby
require 'alog'
```

Include the namespace into your class and configure the tag that you want the library to show/display. 
Any tag that is not configured will be skipped

```ruby
class MyApp
  include Alog
  
  # STEP 1: Configuration
  #
  # Configure logger and bind the logger to a key
  # Whatever on the right side shall be passed to the standard library Logger object
  # The array construct is necesary because *args is used in 
  # passing the parameters to actual standard library Logger object via new()
  LogFacts[:stdout] = [STDOUT]  
  # Also multiple loggers can be configured by creating multiple keys
  LogFacts[:app_file] = ['app.log',10, 1024000]
  ...
  
  # STEP 2: Define which keys to activate
  # Any block/log output tagged by the key included in this array shall be printed
  LogTag << :feature_1
  LogTag << :feature_2
  ...
  # Any tag that is not configured inside the LogTag will not be printed out
  # If the list is empty, no log under the library shall be printed.
  # Or there is more then dozens tags and want to show all, use this method
  show_all_tags

  
  # STEP 3: Create the logging
  def my_method(p1, p2)
    # Method 1: block logging
    l(:feature_1, type: :debug, logEng: [:stdout]) do
      # All clog() call inside this block will be tagged with key :feature_1
      # enabling the key :feature_1 shall show all log messages inside this block or disabling otherwise
      ...
      ...
      # If only message is given, the following is the default:
      # 1. The system shall use the first logger, in this case it will be using logger with key :stdout
      # 2. The logger will use debug level to log the message 
      #    (System will use log level debug if the log level is not given in the l() above via key 'type'.
      clog "This is logging message"
      ...
      ...
      # If the message and tag is given
      # 1. The tag shall override the global configuration of logging level debug (to whatever level given by developer)
      # Note that 'error' logging level will ignore the tag-skipping feature since error conditions (and its messages) will likely 
      # affect the subsequent code/logic of a system. Therefore 'error' will always be printed.
      clog "Error in defining X", :error
      clog "Reach here means ok", :info
      
      # Asking the Alogger to write to other logger at the same time, 
      # overriding the parameter given in the l().
      clog "This will written to both :stdout and :app_file", logEng: [:stdout,:app_file]
      ...
      ...
    end
    
    (business logic continues...)
    ...
    ...
    # Method 2: Call clog() directly
    # Param 1 : Log messages
    # Param 2 : Log level [:debug|:info|:error] (empty = :debug)
    # Param 3 : Tag of the log message (empty = :global)
    # Param 4 : Log engine to be used (refers to LogFacts hash entries above) (empty = first LogFacts key)
    clog("Business continue up to level 2", :debug, :feature_2, [:stdout])
    ...
    
  end

  def my_method2(p2)
    # Method 3 : Create the AOlogger object
    # AOlogger is meant to be proxy for standard Logger, with the tagging and multiple log engines included
    # The initialize parameter is an array containing key to the LogFacts above...
    # In the following case, the AOlogger shall only configured to :stdout configuration (refers above) 
    # and all logging shall be tagged with key :feature_m
    @log = AOlogger.new(:feature_m, [:stdout])
    ...
    ...
    # This behave like standard logging engine
    @log.debug "Code reached here..."
    @log.error "Oppss... We did it again!"
    ...
    ...
    # this API is more explicit and replace all global values
    @log.log("this only shown if tag :feature_x is activated", :debug, :feature_x, [:app_file])
    
  end

end
```


## TODO

Library not yet tested extensively under multi-threaded applications. Some variables may not be thread safe.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chrisliaw/alog.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
