#!/usr/bin/python
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.firefox.options import Options
from time import sleep
firefox_options = Options()
firefox_options.add_argument("-headless")
driver = webdriver.Firefox(options = firefox_options)
driver.get("https://www.twitch.tv")
sleep(5)

links = driver.find_elements(By.XPATH, "//a[@data-a-target='preview-card-image-link']")
for link in links:
    print(link.get_attribute('href'))
driver.quit()
print(quit)
quit()
