class User < ActiveRecord::Base
  has_many :projects

  def self.find_or_create_from_oauth(username)
    find_by(username: username) || User.create!(username: username)
  end
end
