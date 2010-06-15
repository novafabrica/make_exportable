require "active_record"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'make_exportable'))

require 'core'
require 'errors'
require 'exportable_format'
require 'make_exportable_helper'

# TODO: make format loading dynamic
require 'formats/csv'
require 'formats/html'
require 'formats/excel'
require 'formats/tsv'
require 'formats/xml'
require 'formats/json'

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, MakeExportable
end
