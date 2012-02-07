#!/usr/bin/env ruby -rubygems
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'

require 'model.rb'
require 'experiments.rb'

set :public_folder, File.dirname(__FILE__) + '/static'
enable :sessions

get '/' do
  'Hello world! oh no robot hurray cool robot things so many'
end

get '/create' do
  c = Canvas.create(:experiment => "dev", :platform => "OSX", :canvas_json => "[1,2,3]")
  c.platform
end


before '/exp/:experiment*' do |experiment|
  if @exp = Experiment.where(:name => experiment).count == 0
    halt 404, "Invalid experiment"
  end
end

get '/exp/:experiment' do |experiment|
  @exp = Experiment.where(:name => experiment).first
  @scripts = @exp.scripts

  haml :experiment
end

post '/exp/:experiment/results' do |experiment|
  @exp = Experiment.where(:name => experiment).first

  # Policy: we store one sample per user-agent.
  # When and if we discover a collision here, we'll revisit.
  @result = Canvas.where(:useragent => env["HTTP_USER_AGENT"],
                         :experiment_id => @exp.id).first

  puts "Creating new canvas" if @result.nil?
  @result = Canvas.create() if @result.nil?

  @result.experiment_id = @exp.id
  @result.useragent = env["HTTP_USER_AGENT"]
  @result.title = params["title"]
  @result.canvas_json = params["pixels"]
  @result.save

  redirect "/exp/#{experiment}/results/#{@result.id}"

  puts
  puts @result
  puts @exp.id
  puts params["title"]
end

get '/exp/:experiment/results/:id' do |experiment, id|
  # get the response, display it
  @exp = Experiment.where(:name => experiment).first

  # Policy: we store one sample per user-agent.
  # When and if we discover a collision here, we'll revisit.
  @result = Canvas.where(:id => id,
                         :experiment_id => @exp.id).first

  haml :result
end

