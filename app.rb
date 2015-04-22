require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'sass'
require 'sinatra/activerecord'
require 'pg'
require 'dotenv'
require 'oauth'

configure :development, :test do
  require 'pry'
end

Dir[File.join(File.dirname(__FILE__), 'lib', '**', '*.rb')].each do |file|
  require file
  also_reload file
end

Dotenv.load

CALLBACK_URL = "http://localhost:4567/oauth/callback"
OAUTH_PROVIDER = "https://www.ravelry.com"

use Rack::Session::Cookie, {
  expire_after: 2592000, secret: ENV["secret"]
}

helpers do
  def current_user
    User.find_by(username: session[:username])
  end

  def user_signed_in?
    !current_user.nil?
  end
end

def build_queue(username)
  queue = JSON.parse(session[:access_token].get("https://api.ravelry.com/people/#{username}/queue/list.json").response.body)

  queue["queued_projects"].each do |project|
    new_project = Project.new
    new_project.user_id = User.find_by(username: @username).id
    new_project.photo = project["best_photo"]["small_url"]
    new_project.name = project["short_pattern_name"]
    new_project.pattern_id = project["pattern_id"]
    new_project.queued_id = project["id"]
    new_project.save
  end
end

get "/sign_out" do
  session[:username] = nil
  redirect "/"
end

get "/sign_in" do
  consumer = OAuth::Consumer.new(ENV["RAV_ACCESS_KEY"], ENV["RAV_SECRET_KEY"], site: OAUTH_PROVIDER)
  request_token = consumer.get_request_token(oauth_callback: CALLBACK_URL)

  session[:request_token] = request_token
  redirect request_token.authorize_url(oauth_callback: CALLBACK_URL)
end

get "/oauth/callback" do
  request_token = session[:request_token]
  session[:access_token] = request_token.get_access_token(oauth_verifier: params[:oauth_verifier])
  session[:username] = params[:username]
  User.find_or_create_from_oauth(session[:username])
  redirect '/main'
end

get '/' do
  user = User.find_by(username: session[:username])

  if (user_signed_in? && !Project.where(:user_id == current_user.id).any?)
    build_queue(user.username)
  end

  erb :login
end

get '/main' do
  if (user_signed_in? && !Project.where(:user_id == current_user.id).any?)
    build_queue(current_user.username)
  end

  @project = Project.where(:user_id == current_user.id).order("RANDOM()").first
  pattern = JSON.parse(session[:access_token]
                      .get("https://api.ravelry.com/patterns/#{@project.pattern_id}.json").response.body)

  @photos = []
  pattern["pattern"]["photos"].each do |photo|
    @photos << photo["medium_url"]
  end

  erb :index
end
