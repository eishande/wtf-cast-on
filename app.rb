require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'sass'
require 'sinatra/activerecord'
require 'pg'
require 'httparty'
require 'dotenv'

configure :development, :test do
  require 'pry'
  require 'capybara'
  require 'factory_girl'
  require 'rspec'
  require 'launchy'
end

require_relative "lib/ravelry"

Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
  require file
  also_reload file
end

Dotenv.load

RAV = Ravelry.new(ENV["RAV_ACCESS_KEY"], ENV["RAV_PERSONAL_KEY"])
my_queue = JSON.parse(RAV.queue.response.body)

my_queue["queued_projects"].each do |project|
  new_project = Project.new
  new_project.photo = project["best_photo"]["small_url"]
  new_project.name = project["short_pattern_name"]
  new_project.pattern_id = project["pattern_id"]
  new_project.queued_id = project["id"]
  new_project.save
end

get '/' do
  @project = Project.order("RANDOM()").first
  pattern = JSON.parse(RAV.pattern(@project.pattern_id).response.body)
  @photos = []
  pattern["pattern"]["photos"].each do |photo|
    @photos << photo["medium_url"]
  end
  erb :index
end

get '/projects/:id' do
  @project = Project.find(params[:id])
  detail = JSON.parse(RAV.single_project(@project.queued_id).response.body)
  @photos = []
  detail["queued_project"]["queued_stashes"].each do |stash|
    @photos << stash["stash"]["photos"][0]["small_url"]
  end
  erb :show
end
