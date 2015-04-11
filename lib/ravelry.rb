class Ravelry
  include HTTParty
  base_uri 'https://api.ravelry.com'
  format :json

  def initialize(u, p)
    @auth = {username: u, password: p}
  end

  def queue(options={})
    options.merge!({basic_auth: @auth})
    self.class.get('/people/catrionag/queue/list.json', options)
  end

  def single_project(id, options={})
    options.merge!({basic_auth: @auth})
    self.class.get("/people/catrionag/queue/#{id}.json", options)
  end

  def current_user(options={})
    options.merge!({basic_auth: @auth})
    self.class.get('/current_user.json', options)
  end

  def pattern(id, options={})
    options.merge!({basic_auth: @auth})
    self.class.get("/patterns/#{id}.json", options)
  end
end
