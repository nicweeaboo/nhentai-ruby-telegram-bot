%w{telegram/bot nhentai-api rest-client nokogiri down tempfile}.each { |e| require e }
%w{joke.rb neko.rb}.each { |e| require_relative e }

class Bot

  JOKE_TYPES = ['single', 'twopart']
  NEKO_TYPES = ['neko', 'nekolewd']
  MEME_ENDPOINT = 'https://meme-api.herokuapp.com/gimme'

  def initialize

    token = ENV['TELEGRAM_BOT_H']
    
    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message

          case message.text
    
          when '/today', '/today@sadistic_oneesan_ruby_bot'
            today_doujinshi = Doujinshi.new(Time.now.strftime("%d%m%y"))
            if today_doujinshi.exists?
              today_doujinshi_tags = []
              today_doujinshi.tags.each do |tag|
                today_doujinshi_tags << tag.name.gsub!('<span class="name">','')
              end
              bot.api.send_message(chat_id: message.chat.id, 
                text: "<b>Nhentai doujinshi based on today's date #{Time.now.strftime("%d/%m/%y")} (#{Time.now.strftime("%d%m%y")}) </b>\n<a href='#{today_doujinshi.cover}'><b>TITLE: #{today_doujinshi.title}</b></a>\n<b>TAGS: #{today_doujinshi_tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{today_doujinshi.id}'><b>READ NOW</b></a>",
                parse_mode: "HTML")
            else
              bot.api.send_message(chat_id: message.chat.id, text: "Couldn't find any ;/" )
            end

          when /^\/code ([0-9]+)$/
            code = message.text.delete('^0-9')
            doujinshi=Doujinshi.new(code)
            if doujinshi.exists?
              tags = []
              doujinshi.tags.each do |tag|
                tags << tag.name.gsub!('<span class="name">','')
              end
              begin
                cover = doujinshi.cover
              rescue
                html = RestClient.get("https://nhentai.net/g/#{doujinshi.id}/")
                html_parsed=Nokogiri::HTML(html)
                img = html_parsed.css("div#cover>a>img")
                cover = img.attr("data-src").value
              end
                bot.api.send_message(chat_id: message.chat.id, text: "<a href='#{cover}'><b>TITLE: #{doujinshi.title}</b></a>\n<b>TAGS: #{tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{doujinshi.id}'><b>READ NOW</b></a>",
                parse_mode: "HTML")
            else
                bot.api.send_message(chat_id: message.chat.id, text: "Couldn't find any ;/" )
            end
        
          when '/joke', '/joke@sadistic_oneesan_ruby_bot'
            joke = Joke.new(JOKE_TYPES.sample)
            jokes = joke.run
            if joke.type == 'twopart'
              bot.api.send_message(chat_id: message.chat.id, 
                text: "<b>- #{jokes[0]}</b>\n\n- #{jokes[1]}", parse_mode: "HTML")
            else
              bot.api.send_message(chat_id: message.chat.id, 
                text: "#{jokes[0]}")
            end

          when '/instagram', '/instagram@sadistic_oneesan_ruby_bot'
            bot.api.send_message(chat_id: message.chat.id,
              text: "<b>Página Oficial 1 Real a Hora no instagram</b> 🌚\n👉 https://www.instagram.com/1realahora/",
              parse_mode: "HTML",
              disable_web_page_preview: true)

          when '/facebook', '/facebook@sadistic_oneesan_ruby_bot'
            bot.api.send_message(chat_id: message.chat.id, 
              text: "<b>Página Oficial 1 Real a Hora no facebook</b> 🌚\n👉 https://pt-br.facebook.com/1realahora/",
              parse_mode: "HTML",
              disable_web_page_preview: true)
            
          when '/neko', '/neko@sadistic_oneesan_ruby_bot'
            neko = Neko.new(NEKO_TYPES.sample).run
            bot.api.send_message(chat_id: message.chat.id,
              text: "Everybody loves <a href='#{neko}'>neko</a> girls ❤️",
              parse_mode: "HTML")

          when '/random', '/random@sadistic_oneesan_ruby_bot'
            begin
              doujinshi = Doujinshi.new(rand(10000...999999))
              puts doujinshi.id
            end until doujinshi.exists?
            tags = []
            doujinshi.tags.each do |tag|
              tags << tag.name.gsub!('<span class="name">','')
            end
            begin
              cover = doujinshi.cover
            rescue
              html = RestClient.get("https://nhentai.net/g/#{doujinshi.id}/")
              html_parsed=Nokogiri::HTML(html)
              img = html_parsed.css("div#cover>a>img")
              cover = img.attr("data-src").value
            end
              bot.api.send_message(chat_id: message.chat.id, text: "<a href='#{cover}'><b>TITLE: #{doujinshi.title}</b></a>\n<b>TAGS: #{tags[0..12].join(', ')}</b>\n<a href='https://nhentai.net/g/#{doujinshi.id}'><b>READ NOW</b></a>",
              parse_mode: "HTML")

          when '/meme', '/meme@sadistic_oneesan_ruby_bot'
            uri = URI(MEME_ENDPOINT)
            response = Net::HTTP.get(uri)
            meme_url = JSON.parse(response)['url']
            meme_extension = meme_url.split('.')[2]
            meme = Tempfile.new(['meme', meme_extension])
            begin
              meme = Down.download(meme_url)
              bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new(meme, "image/#{meme_extension}"))
            ensure
              meme.close
              meme.unlink
            end
          
          when '/feet', '/feet@sadistic_oneesan_ruby_bot'
            url = "https://yande.re/post?page=#{rand(1..800)}&tags=feet"
            html = RestClient.get(url)  
            html_parsed = Nokogiri::HTML(html)
            list= html_parsed.css("ul#post-list-posts")
            elements = list.css("li>a.directlink")
            images = []
            elements.each {|item| images << item['href']}
            images.shuffle!
            begin
              retries ||= 0
              image_1 = images.sample
              image_2 = images.sample
              image_3 = images.sample
              media = [
                Telegram::Bot::Types::InputMediaPhoto.new(media:"#{image_1}"),
                Telegram::Bot::Types::InputMediaPhoto.new(media:"#{image_2}"),
                Telegram::Bot::Types::InputMediaPhoto.new(media:"#{image_3}")
              ]
              bot.api.send_media_group(chat_id: message.chat.id, media: media)
              sleep(40)
            rescue Telegram::Bot::Exceptions::ResponseError
              sleep(60)
              retry if (retries += 1) < 3
              bot.api.send_message(chat_id: message.chat.id, text: "Something went wrong...")
            end
          
          when '/milf', '/milf@sadistic_oneesan_ruby_bot'
            url = "https://nhentai.net/search/?q=milf+-chinese+-japanese&sort=popular-week&page=#{rand(1..10)}"
            html = RestClient.get(url)
            html_parsed = Nokogiri::HTML(html)
            list = html_parsed.css("div.gallery a.cover")
            milf = list.to_a.sample
            bot.api.send_message(chat_id: message.chat.id,
              text: "I recommend <a href='#{milf.css('img.lazyload').attr('data-src').value}'>this</a> one 👌🏼\n<b>READ HERE:</b> nhentai.net#{milf.values[0]}", parse_mode: "HTML")
          
          when '/about', '/about@sadistic_oneesan_ruby_bot'
            bot.api.send_message(chat_id: message.chat.id,
              text: "Bot made by <b>nicweeaboo</b>\n👉🏼 Bot source code: <a href='https://github.com/nicweeaboo/nhentai-ruby-telegram-bot'>Check out here</a>\n\nPls do not google my username.", parse_mode: "HTML")
          end
        end
      end
    end

  end

end