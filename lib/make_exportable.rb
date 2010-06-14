require "active_record"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'nova_fabrica/make_exportable'
require 'nova_fabrica/make_exportable_helper'
require 'nova_fabrica/make_exportable_errors'

# TODO: make format loading dynamic & user editable
require 'nova_fabrica/formats/exportable_format'
require 'nova_fabrica/formats/csv'
require 'nova_fabrica/formats/html'
require 'nova_fabrica/formats/excel'
require 'nova_fabrica/formats/tsv'
require 'nova_fabrica/formats/xml'
require 'nova_fabrica/formats/json'


$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, NovaFabrica::MakeExportable
end
