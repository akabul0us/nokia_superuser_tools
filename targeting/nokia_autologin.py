#!/usr/bin/env python3
'''
THIS IS A WORK IN PROGRESS -- IT'S NOT WORKING YET
of course if you want to make it work and then open a pull request, that would be cool
otherwise, STFU
--management
'''
import sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

nokia = sys.argv[1]

CHROMEDRIVER_PATH = '/usr/bin/chromedriver'

chrome_options = Options()
chrome_options.add_argument("--headless")
chrome_options.add_argument("start-maximized")
chrome_options.add_argument("--allow-running-insecure-content") 
chrome_options.add_argument(f"--unsafely-treat-insecure-origin-as-secure=https://{nokia}")
chrome_options.add_argument("--disable-blink-features")
chrome_options.add_argument("--disable-blink-features=AutomationControlled")

LOGIN_PAGE = nokia
ACCOUNT = "AdminGPON"
PASSWORD = "ALC#FGU"

driver = webdriver.Chrome(CHROMEDRIVER_PATH, options=chrome_options)
driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
driver.execute_cdp_cmd('Network.setUserAgentOverride', {"userAgent": 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.53 Safari/537.36'})

driver.get(f"https://{nokia}")
username = driver.find_element_by_name("name")
username.send_keys(ACCOUNT)
password = driver.find_element_by_name("pswd")
password.send_keys(PASSWORD)

submit_button = driver.find_element_by_name("loginBT")
submit_button.click()


driver.get("")
text_element = driver.find_elements_by_xpath('//*')

text = text_element

for t in text:
    print(t.text)
