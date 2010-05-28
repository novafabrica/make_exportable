require "active_record"
require "csv"

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'nova_fabrica/make_exportable'
require 'nova_fabrica/make_exportable_helper'
require 'nova_fabrica/make_exportable_errors'

$LOAD_PATH.shift

if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, NovaFabrica::MakeExportable
end