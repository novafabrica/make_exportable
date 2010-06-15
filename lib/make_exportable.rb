require "active_record"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'make_exportable'))

require 'core'
require 'errors'
require 'exportable_format'
require 'make_exportable_helper'

# TODO: make format loading dynamic
require 'exportable_formats/csv'
require 'exportable_formats/html'
require 'exportable_formats/excel'
require 'exportable_formats/tsv'
require 'exportable_formats/xml'
require 'exportable_formats/json'

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, MakeExportable
end
