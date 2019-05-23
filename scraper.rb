require 'selenium-webdriver'
require 'yaml'

config = YAML.load_file('config.yml')
targets = YAML.load_file('targets.yml')

options = Selenium::WebDriver::Chrome::Options.new(args: ['headless', '--blink-settings=imagesEnabled=false'])
driver = Selenium::WebDriver.for(:chrome, options: options)

def login(driver)
    driver.navigate.to "https://www.facebook.com"
    driver.find_element(:id, targets['login']['username']).send_keys(config['username'])
    driver.find_element(:id, targets['login']['password']).send_keys(config['password'])
    driver.find_element(:id, targets['login']['form']).submit
end

def collectThreadIds(driver, groupId)
    driver.navigate.to "https://www.facebook.com/groups/#{groupId}/"
end

def saveThread(driver, groupId, threadId){
    driver.navigate.to "https://www.facebook.com/groups/#{groupId}/permalink/#{threadId}/"
}

def scrollDown(driver)
    lastPageLength = 0
    currentPageLength = driver.execute_script("window.scrollTo(0, document.body.scrollHeight);return document.body.scrollHeight;")
    while (currentPageLength != lastPageLength && currentPageLength < 300000)
        lastPageLength = currentPageLength
        sleep 4
        currentPageLength = driver.execute_script("window.scrollTo(0, document.body.scrollHeight);return document.body.scrollHeight;")
        puts currentPageLength
    end
end
