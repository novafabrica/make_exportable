require "active_record"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'make_exportable'))

require 'core'
require 'errors'
require 'exportable_format'
require 'make_exportable_helper'

Dir.foreach(File.join(File.dirname(__FILE__), 'make_exportable', 'exportable_formats')) do |file|
  next unless File.extname(file) == '.rb'
  require File.join('exportable_formats', File.basename(file, '.rb'))
end

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, MakeExportable
end
