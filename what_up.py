from selenium import webdriver  
from selenium.webdriver.chrome.service import Service  
from selenium.webdriver.common.by import By  
from selenium.webdriver.support.ui import WebDriverWait  
from selenium.webdriver.support import expected_conditions as EC  
import time  
import os  
  
# Inisialisasi driver browser (misalnya Chrome)  
options = webdriver.ChromeOptions()  
options.add_argument("--no-sandbox")  
options.add_argument("--disable-dev-shm-usage")  
options.add_argument("--disable-gpu")  
# options.add_argument("--headless")  # Uncomment this line to run Chrome in headless mode  
# options.add_argument("user-data-dir=C:/Users/user/AppData/Local/Google/Chrome/User Data")  # Sesuaikan path ini  
  
# Inisialisasi Service untuk ChromeDriver  
# service = Service("C:/Users/user/Documents/Python/SISDIG/chromedriver.exe")  # Sesuaikan path ini  
  
# Inisialisasi WebDriver  
nama = input("Nama/grup yang akan dikontak: ")
driver = webdriver.Chrome(options=options)  
  
# Buka WhatsApp Web  
driver.get("https://web.whatsapp.com/")  
  
# Tunggu hingga pengguna berhasil login  
WebDriverWait(driver, 100).until(  
    EC.presence_of_element_located((By.XPATH, '//div[@contenteditable="true"][@data-tab="3"]'))  
)  
  
print("Scan QR code menggunakan HP kamu.")  
  
# Setelah login, cari kontak atau grup  
search_box = driver.find_element(By.XPATH, '//div[@contenteditable="true"][@data-tab="3"]')  
search_box.click()  
search_box.send_keys(nama)  # Ganti dengan nama kontak atau grup yang diinginkan  
time.sleep(2)  # Tunggu sebentar agar hasil pencarian muncul  
  
# Pilih kontak atau grup  
contact = driver.find_element(By.XPATH, f"//span[@title='{nama}']")  # Ganti dengan nama kontak atau grup yang diinginkan  
contact.click()  
  
# Tunggu hingga pesan muncul  
time.sleep(5)  # Tunggu sebentar agar pesan muncul  
  
# Ambil pesan terakhir menggunakan XPath yang diberikan
while True:
    time.sleep(1)
    try:  
        last_message = driver.find_element(By.XPATH, "//div[@class='x3psx0u xwib8y2 xkhd6sd xrmvbpv']/div[@role='row'][last()]//span[@class='_ao3e selectable-text copyable-text']")  
        message_text = last_message.text  
    except Exception as e:  
        message_text = "Pesan terakhir tidak ditemukan"
        print(f"Error: {e}")
        break
    
    # Buat folder untuk menyimpan file jika belum ada  
    folder_path = "WhatsApp_Chat_Exports"  
    if not os.path.exists(folder_path):  
        os.makedirs(folder_path)  
    
    # Ekstrak pesan terakhir ke dalam file teks  
    file_path = os.path.join(folder_path, f"{nama}_chat_last_message.txt")  
    with open(file_path, "w", encoding="utf-8") as f:  
        f.write(message_text) 
    
# Tutup browser  
driver.quit()