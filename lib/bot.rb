require 'telegram/bot'
require 'nhentai-api'
require 'rest-client'
require 'nokogiri'

class Bot

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
          when /\/code/
            code = message.text.delete('^0-9')
            if message.text == "/code #{code}"
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

          end
        end
      end
    end

  end

end