require 'net/http'
require 'json'

class Joke
  
  API_ENDPOINT = 'https://v2.jokeapi.dev/joke/Dark?blacklistFlags=religious,political&type='
  
  attr_accessor :type
  def initialize(type)
    @type = type
  end

  def run
    make_request
    get_joke
  end
  
  private

  def url
    @url ||= API_ENDPOINT + @type
  end

  def make_request
    uri = URI(url)
    response = Net::HTTP.get(uri)
    @result = JSON.parse(response)
  end

  def get_joke
    joke = []
    if type == 'single'
      joke << @result['joke']
    else
      joke << @result['setup']
      joke << @result['delivery']
    end
  end

end