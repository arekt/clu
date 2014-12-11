# encoding: utf-8
$:.unshift File.dirname(__FILE__)
require "lib/clu"
require "lib/pivotal"

@utils = Utils.new
@utils.setup

class Main < Context
  def pivotal
    @utils.context.enter("pivotal")
  end
  def main
    @utils.context.enter("main")
  end
  def actions
    [:quit, :pivotal, :main]
  end
end

while @utils.line = RbReadline.readline(@utils.prompt)
  @utils.run if @utils.line
end
