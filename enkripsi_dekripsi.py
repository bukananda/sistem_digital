import serial
import time

baudrate = 9600  # Ganti dengan baud rate yang sesuai
try:
    # Konfigurasi port serial
    port = "COM4"  # Ganti dengan port serial yang sesuai
    # Inisialisasi objek serial
    ser = serial.Serial(port, baudrate, timeout=5)
except:
    # Konfigurasi port serial
    port = "COM3"
    # Inisialisasi objek serial
    ser = serial.Serial(port, baudrate, timeout=5)

# String data yang akan dikirim
while True:
    pilihan = input("\n1. Masukkan input: \n2. Keluar: \n")
    if pilihan == '1':
        pilihan_mode = input("\n1. Enkripsi: \n2. Dekripsi: \n3. Keluar: \n")
        # data_tx = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
        if pilihan_mode == '1':
            data_from_txt = open(f"WhatsApp_Chat_Exports/aqib_chat_last_message.txt",'r')
            data_tx = data_from_txt.read()
            try:
                # Kirim data ke FPGA
                encoded_string = data_tx.encode()
                ser.write(encoded_string)

                # Tunggu beberapa saat agar FPGA memproses data
                time.sleep(1)
                buffer_byte = ser.in_waiting
                enc_hex = encoded_string.hex().upper()
                data_rx = ser.read(buffer_byte).hex().upper()
                print("\nKey:", " ".join([data_rx[0:64][i:i+2] for i in range(0, len(data_rx[0:64]), 2)]))
                print("Nonce:", " ".join([data_rx[64:88][i:i+2] for i in range(0, len(data_rx[64:88]), 2)]))
                print("Text:",data_tx)
                print("Plain Text Hex:", " ".join([enc_hex[i:i+2] for i in range(0, len(enc_hex), 2)]))
                print("Chacha Hex:", " ".join([data_rx[88:344][i:i+2] for i in range(0, len(data_rx[88:344]), 2)]))

            except serial.SerialTimeoutException as e:
                print("Timeout Error:", e)
            except serial.SerialException as e:
                print("Serial Error:", e)

        elif pilihan_mode == '2':
            key_string = input("Masukkan key: ")
            nonce_string = input("Masukkan nonce: ")
            data_encrypt = input("Masukkan encrypted hex: ")
            data_tx = key_string + " " + nonce_string + " " + data_encrypt
            try:
                # Kirim data ke FPGA
                # Parsing string dan kirim sebagai byte
                nilai_heksa = [int(x, 16) for x in data_tx.split()]
                for nilai in nilai_heksa:
                    ser.write(nilai.to_bytes(1, byteorder='big'))
                ser.write(data_tx.encode())

                # Tunggu beberapa saat agar FPGA memproses data
                time.sleep(1)
                buffer_byte = ser.in_waiting
                data_rx = ser.read(buffer_byte)
                data_hex = data_rx.hex().upper()
                print("\nKey:", " ".join([data_hex[0:64][i:i+2] for i in range(0, len(data_hex[0:64]), 2)]))
                print("Nonce:", " ".join([data_hex[64:88][i:i+2] for i in range(0, len(data_hex[64:88]), 2)]))
                print("Chacha Hex:", " ".join([data_hex[88:344][i:i+2] for i in range(0, len(data_hex[88:344]), 2)]))
                try:
                    data_text = data_rx[44:172].decode('ascii')
                    print("Text:",data_text)
                except:
                    print("Hex tidak dapat dikonversi ke ASCII")

            except serial.SerialTimeoutException as e:
                print("Timeout Error:", e)
            except serial.SerialException as e:
                print("Serial Error:", e)

        elif pilihan_mode == '3':
            ser.close()
            break

        else:
            print("Pilihan invalid")

    elif pilihan == '2':
        ser.close()
        break

    else:
        print("Pilihan invalid")