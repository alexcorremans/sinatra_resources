require 'sinatra'
require 'sinatra/reloader'

enable :sessions

class NameValidator
  def initialize(name, names)
    @name = name.to_s
    @names = names
  end

  def valid?
    validate
    @message.nil?
  end

  def message
    @message
  end

  private

  def validate
    if @name.empty?
      @message = "You need to enter a name."
    elsif @names.include?(@name)
      @message = "#{@name} is already included in our list."
    elsif @name == "new"
      @message = "Very funny. Try another name."
    end
  end
end

def read_members
  return [] unless File.exist?("members.txt")
  File.read("members.txt").split("\n")
end

def store_name(name)
  File.open("members.txt", "a+") do |file|
    file.puts(name)
  end
end

def update_name(old_name, new_name)
  contents = File.read("members.txt")
  new_contents = contents.gsub(old_name, new_name)
  File.open("members.txt", "w") do |file|
    file.puts(new_contents)
  end
end

def delete_name(name)
  members = File.readlines("members.txt")
  File.open("members.txt", "w") do |file|
    members.each do |line|
      file.puts(line) if !line.include?(name)
    end
  end
end

get '/' do
  redirect '/members'
end

get '/members' do
  @members = read_members
  erb :index
end

get '/members/new' do
  erb :new
end

get '/members/:name' do
  @name = params['name']
  @message = session.delete(:message)
  erb :show
end

post '/members' do
  @name = params['name']
  @members = read_members
  validator = NameValidator.new(@name, @members)
  if validator.valid?
    store_name(@name)
    session[:message] = "Successfully stored the member #{@name}."
    redirect "/members/#{@name}"
  else
    @message = validator.message
    erb :new
  end    
end

get '/members/:name/edit' do
  @name = params['name']
  erb :edit
end

put '/members/:name' do
  @old_name = params['name']
  @new_name = params['new_name']
  @members = read_members
  validator = NameValidator.new(@new_name, @members)
  if validator.valid?
    update_name(@old_name, @new_name)
    session[:message] = "Successfully updated the member's details from #{@old_name} to #{@new_name}."
    redirect "/members/#{@new_name}"
  else
    @message = validator.message
    @name = params['name']
    erb :edit
  end
end

get '/members/:name/delete' do
  @name = params['name']
  erb :delete
end

delete '/members/:name' do
  @name = params['name']
  delete_name(@name)
  redirect "/members"
end