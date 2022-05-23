%w{telegram/bot nhentai-api rest-client nokogiri down tempfile}.each { |e| require e }
%w{joke.rb neko.rb}.each { |e| require_relative e }

class Bot

  JOKE_TYPES = ['single', 'twopart']
  NEKO_TYPES = ['neko', 'nekolewd']
  MEME_ENDPOINT = 'https://meme-api.herokuapp.com/gimme'

  def initialize
    token = ENV['TELEGRAM_BOT_H']

    Telegram::Bot::Client.run(token) do |bot|
      begin
        bot.listen do |message|
          return unless message == Telegram::Bot::Types::Message

          if %w[
              /today /code /joke /neko /random /genshin_impact /feet /yuri /thighhighs /milf /about /tags
              /today@sadistic_oneesan_ruby_bot /joke@sadistic_oneesan_ruby_bot /neko@sadistic_oneesan_ruby_bot
              /random@sadistic_oneesan_ruby_bot /genshin_impact@sadistic_oneesan_ruby_bot /feet@sadistic_oneesan_ruby_bot
              /yuri@sadistic_oneesan_ruby_bot /thighhighs@sadistic_oneesan_ruby_bot /milf@sadistic_oneesan_ruby_bot
              /about@sadistic_oneesan_ruby_bot].include?(message.text)
            method = message.text.match(/\/(\w+)/)
            send(method, bot, message)
          end
        end
      rescue Telegram::Bot::Exceptions::ResponseError => e
        retry
      end
    end

  end

  def today(bot, message)
    begin
      today_doujinshi = Doujinshi.new(id: Time.now.strftime("%d%m%y"))
    rescue Exception => e
      bot.api.send_message(chat_id: message.chat.id, text:"Something went very wrong...")
      break
    end
    if today_doujinshi.exists?
      today_doujinshi_tags = today_doujinshi.tags.map { _1.name }
      bot.api.send_message(chat_id: message.chat.id,
                           text: "<b>Nhentai doujinshi based on today's date #{Time.now.strftime("%d/%m/%y")} (#{Time.now.strftime("%d%m%y")}) </b>\n<a href='#{today_doujinshi.cover}'><b>TITLE: #{today_doujinshi.title(type: :pretty)}</b></a>\n<b>TAGS: #{today_doujinshi_tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{today_doujinshi.id}'><b>READ NOW</b></a>",
                           parse_mode: "HTML")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Couldn't find any ;/" )
    end
  end

  def code(bot, message)
    code = message.text.delete('^0-9')
    begin
      doujinshi = Doujinshi.new(id: code)
    rescue Exception => e
      bot.api.send_message(chat_id: message.chat.id, text:"Something went very wrong...")
      break
    end
    if doujinshi.exists?
      tags = doujinshi.tags&.map { _1.name } || ["TagsError"]
      begin
        cover = doujinshi.cover
      rescue
        html = RestClient.get("https://nhentai.net/g/#{doujinshi.id}/")
        html_parsed=Nokogiri::HTML(html)
        img = html_parsed.css("div#cover>a>img")
        cover = img.attr("data-src").value
      end
      bot.api.send_message(chat_id: message.chat.id, text: "<a href='#{cover}'><b>TITLE: #{doujinshi.title(type: :pretty)}</b></a>\n<b>TAGS: #{tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{doujinshi.id}'><b>READ NOW</b></a>",
                           parse_mode: "HTML")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Couldn't find any ;/" )
    end
  end

  def joke(bot, message)
    joke = Joke.new(JOKE_TYPES.sample)
    jokes = joke.run
    if joke.type == 'twopart'
      bot.api.send_message(chat_id: message.chat.id,
                           text: "<b>- #{jokes[0]}</b>\n\n- #{jokes[1]}", parse_mode: "HTML")
    else
      bot.api.send_message(chat_id: message.chat.id,
                           text: "#{jokes[0]}")
    end
  end

  def neko(bot, message)
    neko = Neko.new(NEKO_TYPES.sample).run
    bot.api.send_message(chat_id: message.chat.id,
                         text: "Everybody loves <a href='#{neko}'>neko</a> girls ❤️",
                         parse_mode: "HTML")
  end

  def random(bot, message)
    begin
      begin
        doujinshi = Doujinshi.random
      rescue Exception => e
        bot.api.send_message(chat_id: message.chat.id, text:"Something went very wrong...")
        break
      end
    end until doujinshi.exists?
    tags = doujinshi.tags&.map { _1.name } || ["TagsError"]
    begin
      cover = doujinshi.cover
    rescue
      html = RestClient.get("https://nhentai.net/g/#{doujinshi.id}/")
      html_parsed=Nokogiri::HTML(html)
      img = html_parsed.css("div#cover>a>img")
      cover = img.attr("data-src").value
    end
    bot.api.send_message(chat_id: message.chat.id, text: "<a href='#{cover}'><b>TITLE: #{doujinshi.title(type: :pretty)}</b></a>\n<b>TAGS: #{tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{doujinshi.id}'><b>READ NOW</b></a>",
                         parse_mode: "HTML")
  end

  def genshin_impact(bot, message)
    begin
      retries ||= 0
      url = "https://yande.re/post?page=#{rand(1..100)}&tags=genshin_impact"
      html = RestClient.get(url)
      html_parsed = Nokogiri::HTML(html)
      list = html_parsed.css("ul#post-list-posts")
      elements = list.css("li>a.directlink")
      media =
        elements
          .map { _1['href']}
          .shuffle
          .map { Telegram::Bot::Types::InputMediaPhoto.new(media: _1) }
      bot.api.send_media_group(chat_id: message.chat.id, media: media)
    rescue Telegram::Bot::Exceptions::ResponseError, RestClient::ExceptionWithResponse
      sleep(20)
      retry if (retries += 1) < 3
      bot.api.send_photo(chat_id: message.chat.id,
                         caption: "Something went. Sorry onii-chan",
                         photo: Faraday::UploadIO.new(img, 'image/jpg'))
    end
  end

  def feet(bot, message)
    begin
      retries ||= 0
      url = "https://yande.re/post?page=#{rand(1..800)}&tags=feet"
      html = RestClient.get(url)
      html_parsed = Nokogiri::HTML(html)
      list= html_parsed.css("ul#post-list-posts")
      elements = list.css("li>a.directlink")
      media =
        elements
          .map { _1['href']}
          .shuffle
          .map { Telegram::Bot::Types::InputMediaPhoto.new(media: _1) }
      bot.api.send_media_group(chat_id: message.chat.id, media: media)
    rescue Telegram::Bot::Exceptions::ResponseError, RestClient::ExceptionWithResponse
      sleep(20)
      retry if (retries += 1) < 2
      bot.api.send_photo(chat_id: message.chat.id,
                         caption: "Something went. Sorry onii-chan",
                         photo: Faraday::UploadIO.new(img, 'image/jpg'))
    end
  end

  def yuri(bot, message)
    begin
      retries ||= 0
      url = "https://yande.re/post?page=#{rand(1..300)}&tags=yuri"
      html = RestClient.get(url)
      html_parsed = Nokogiri::HTML(html)
      list = html_parsed.css("ul#post-list-posts")
      elements = list.css("li>a.directlink")
      media =
        elements
          .map { _1['href']}
          .shuffle
          .map { Telegram::Bot::Types::InputMediaPhoto.new(media: _1) }
      bot.api.send_media_group(chat_id: message.chat.id, media: media)
    rescue Telegram::Bot::Exceptions::ResponseError, RestClient::ExceptionWithResponse
      sleep(20)
      retry if (retries += 1) < 2
      bot.api.send_photo(chat_id: message.chat.id,
                         caption: "Something went. Sorry onii-chan",
                         photo: Faraday::UploadIO.new(img, 'image/jpg'))
    end
  end

  def thighhighs(bot, message)
    begin
      retries ||= 0
      url = "https://yande.re/post?page=#{rand(1..300)}&tags=thighhighs"
      html = RestClient.get(url)
      html_parsed = Nokogiri::HTML(html)
      list= html_parsed.css("ul#post-list-posts")
      elements = list.css("li>a.directlink")
      media =
        elements
          .map { _1['href']}
          .shuffle
          .map { Telegram::Bot::Types::InputMediaPhoto.new(media: _1) }
      bot.api.send_media_group(chat_id: message.chat.id, media: media)
    rescue Telegram::Bot::Exceptions::ResponseError, RestClient::ExceptionWithResponse
      sleep(20)
      retry if (retries += 1) < 2
      img = Dir['public/images/default/*'].sample
      bot.api.send_photo(chat_id: message.chat.id,
                         caption: "Something went. Sorry onii-chan",
                         photo: Faraday::UploadIO.new(img, 'image/jpg'))
    end
  end

  def milf(bot, message)
    search = Search.new(options: { keywords: { included: ["milf"], excluded: ["chinese", "japanese"] } }, sort: :week, page: rand(1..10))
    milf = search.listing.sample
    bot.api.send_message(chat_id: message.chat.id,
                         text: "I recommend <a href='#{milf.cover}'>this</a> one 👌🏼\n<b>READ HERE:</b> nhentai.net/g/#{milf.id}", parse_mode: "HTML")
  end

  def about(bot, message)
    bot.api.send_message(chat_id: message.chat.id,
                         text: "Bot made by <b>nicweeaboo</b>\n👉🏼 Bot source code: <a href='https://github.com/nicweeaboo/nhentai-ruby-telegram-bot'>Check out here</a>\n\nPls do not google my username.", parse_mode: "HTML")
  end

  def tags(bot, message)
    tags = message.text.sub(/\/tag\s/,'')
    search = Search.new(options: { keywords: { included: tags.split('+') } }, sort: :today)
    begin
      result = search.listing.sample
      bot.api.send_message(chat_id: message.chat.id,
                           text: "I recommend <a href='#{result.cover}'>this</a> one 👌🏼\n<b>READ HERE:</b> nhentai.net/g/#{result.id}", parse_mode: "HTML")
    rescue StandardError => e
      img = Dir['public/images/default/*'].sample
      bot.api.send_photo(chat_id: message.chat.id,
                         caption: "I couldn't find anything. Sorry onii-chan",
                         photo: Faraday::UploadIO.new(img, 'image/jpg'))
    end
  end

end
