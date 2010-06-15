require "active_record"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'nova_fabrica'))

require 'make_exportable'
require 'make_exportable_helper'
require 'make_exportable_errors'

# TODO: make format loading dynamic
require 'formats/exportable_format'
require 'formats/csv'
require 'formats/html'
require 'formats/excel'
require 'formats/tsv'
require 'formats/xml'
require 'formats/json'

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, NovaFabrica::MakeExportable
end
