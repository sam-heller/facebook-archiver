require 'watir'
require 'nokogiri'
require 'json'


class Scraper
    # Seconds in a week (for the convenients)
    @weekSeconds = 604800
    @currentGroupId = ''
    @threadIds = []
    @pageSource = ''
    

    def initialize configPath
        @config = YAML.load_file(configPath)
        @targets  = YAML.load_file(@config['path']['targets'])
        @javascript = YAML.load_file(@config['path']['javascript'])
        @browser = Watir::Browser.new :chrome, headless: true

    end
    
    def login
        @browser.goto "https://m.facebook.com"
        @browser.text_field(id:  @targets['login']['username']).set @config['username']
        @browser.text_field(id: @targets['login']['password']).set @config['password']
        @browser.button(text: @targets['login']['submit_text']).click
        @browser.link(text: 'Not Now').wait_until(&:exists?)
        
    end

    def getGroupThreads groupId, scrapeUntilDate = false
        @currentGroupId = groupId
        @browser.goto "https://m.facebook.com/groups/#{@currentGroupId}/"
    end

    def loadPrevious
        previous = @browser.link(text: /View previous.*/)        
        while previous.exists?
            previous.click
            sleep(2)
            previous = @browser.link(text: /View previous.*/)
        end
    end

    def loadReplies
        @browser.links(visible_text: /[0-9]* repl(y|ies)/).each do |el| 
            el.click; 
        end
    end

    def saveGroupThread groupId, threadId
        thread = {}
        @browser.goto "https://m.facebook.com/groups/#{groupId}?view=permalink&id=#{threadId}"
        loadPrevious
        loadReplies

        story = Nokogiri::HTML.fragment(@browser.div(class:'story_body_container').inner_html)
        thread['author'] = story.search('h3 > span > strong > a')[0].inner_text
        thread['post'] = story.search('._5nk5').inner_text
        thread['date'] = story.search('abbr').inner_text
        thread['reaction_link'] = @browser.a(class: '_45m8').attribute_value('href')
        thread['comments'] = []
        @browser.divs(data_sigil: 'comment').each do | comment | 
            doc = Nokogiri::HTML.fragment(comment.inner_html)
            comment = {}
            comment['author'] = doc.search('._2b00 > a > i').attribute('aria-label')
            comment['timing'] = doc.search('._2b0a')[0].inner_text 
            comment['text'] = doc.search('[data-sigil=comment-body]')[0].inner_text
            comment['reaction_link'] = doc.search('._4edm')[0].attr('href') if (doc.search('._4edm').length > 0) 
            comment['replies'] = []        
            doc.search('._2a_i').each do |com|
                reply = {}
                reply['author'] = com.search('i').attr('aria-label')
                reply['timing'] = com.search('abbr._2b0a').inner_text
                reply['text'] = com.search('[data-sigil=comment-body]').inner_text
                reply['reaction_link'] = com.search('._4edm')[0].attr('href') if (com.search('._4edm').length > 0)
                comment['replies'].push(reply)
            end
            thread['comments'].push(comment)
        end
        File.open("out.json","w") do |f|
            f.write(thread.to_json)
          end
    end
end