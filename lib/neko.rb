require 'net/http'
require 'json'

class Neko
  
  API_ENDPOINT = 'https://neko-love.xyz/api/v1/'
  
  attr_accessor :type
  def initialize(type)
    @type = type
  end

  def run
    make_request
    get_neko
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

  def get_neko
    neko = @result['url']
  end

end