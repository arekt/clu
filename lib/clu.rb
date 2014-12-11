require 'rubygems'
require 'bundler/setup'
require 'readline'
require 'active_support/all'
require 'active_resource'
Bundler.require

Dotenv.load

class Context
  include Redis::Objects
  value :current_context_name
  def initialize(utils)
    @utils = utils
    @loaded_contexts = {}
  end
  def id
    "context_#{self.class.name.downcase}"
  end

  def actions
    [:quit]
  end

  def enter(context_name)
    @current = find(context_name)
    @current.setup
    @utils.context.current_context_name = context_name
    @current
  end
  def setup
  end

  def find(context_name=nil)
    context = context_name ? @loaded_contexts[context_name.to_sym] : @loaded_contexts[:main]
    begin
      if context.nil?
        context = context_name.to_s.split("::").map(&:capitalize).join("::").camelize.constantize.new(@utils)
        @loaded_contexts[context_name.to_sym] = context
      end
    rescue Exception => e
      puts "Error: #{e}"
      puts "Couldn't find context: #{context_name}"
      context = @loaded_contexts[:main] || Main.new(@utils)
    end
    context
  end

  def complete_arguments_for(line)
    [] #TODO
  end

  def current
    @current ||= find(current_context_name.value)
  end

  def quit
    exit
  end
end

class Main < Context
  def main
    @utils.context.enter("main")
  end
  def actions
    [:quit, :main]
  end
end

class Utils
  attr_accessor :line, :context
  def prompt
    print Rainbow(Time.new.strftime("%H:%M:%S ")).blue.bright.bright
    print @context.current.prompt if @context.current.respond_to?(:prompt)
    puts Rainbow(@context.current.class.name).yellow
    "> "
  end
  def setup
    setup_readline
    @context = Context.new(self)
    @context.current.setup
  end
  def setup_readline
    comp = proc do |s|
      ss = s.force_encoding("UTF-8")
      matching_actions = @context.current.actions.map(&:to_s) || []
      if ss.present?
        matching_actions += @context.current.complete_arguments_for(ss) if ss && @context.current.complete_arguments_for(ss)
        matching_actions += @context.find(:main).actions.map(&:to_s)
      end
      matching_actions.uniq.grep(/^#{Regexp.escape(ss)}/)
    end
    Readline.completion_append_character = " "
    Readline.completion_proc = comp
    Readline.basic_word_break_characters = " "
    Readline.completer_word_break_characters = "\n"
  end
  def run
    Readline::HISTORY.push(@line)
    if result = @line.match(/^(\w+)\:(\w+ .*)/)
      execute_in_context(result[2], result[1])
    else
      execute_in_context(line) || execute_in_context(line, :main)
    end
  end
  def execute_in_context(line, context_name=nil)
    context = context_name ? @context.find(context_name) : @context.current
    command = context.actions.detect do |command|
      line.match /^(#{command} (.*))|^(#{command})/
    end
    if command
      if $2.present?
        context.method(command).call(*$2.split(" "))
      else
        context.method(command).call
      end
    else
      false
    end
  end
end
