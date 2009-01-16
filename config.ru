require 'rubygems'
require 'sinatra/base'
require 'glug'

Glug.set :repo, File.expand_path(File.dirname(__FILE__))

run Glug.new
