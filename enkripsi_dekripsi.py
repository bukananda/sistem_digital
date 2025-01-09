import serial
import time

# Konfigurasi port serial
port = "COM4"  # Ganti dengan port serial yang sesuai
baudrate = 9600  # Ganti dengan baud rate yang sesuai

# Inisialisasi objek serial
ser = serial.Serial(port, baudrate, timeout=5)

# String data yang akan dikirim
while True:
    pilihan = input("\n1. Masukkan input: \n2. Keluar: \n")
    if pilihan == '1':
        pilihan_mode = input("\n1. Enkripsi: \n2. Dekripsi: \n3. Keluar: \n")
        # data_tx = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
        if pilihan_mode == '1':
            data_tx = input("Masukkan plain text: ")
            try:
                # Kirim data ke FPGA
                ser.write(data_tx.encode())

                # Tunggu beberapa saat agar FPGA memproses data
                time.sleep(1)
                buffer_byte = ser.in_waiting
                data_rx = ser.read(buffer_byte).hex().upper()
                print("\nKey:", " ".join([data_rx[0:64][i:i+2] for i in range(0, len(data_rx[0:64]), 2)]))
                print("Nonce:", " ".join([data_rx[64:88][i:i+2] for i in range(0, len(data_rx[64:88]), 2)]))
                print("Chacha Hex:", " ".join([data_rx[88:344][i:i+2] for i in range(0, len(data_rx[88:344]), 2)]))

            except serial.SerialTimeoutException as e:
                print("Timeout Error:", e)
            except serial.SerialException as e:
                print("Serial Error:", e)

        elif pilihan_mode == '2':
            data_tx = input("Masukkan enkripted hex: ")
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
                data_text = data_rx[44:172].decode('ascii')
                print("Text:",data_text)

            except serial.SerialTimeoutException as e:
                print("Timeout Error:", e)
            except serial.SerialException as e:
                print("Serial Error:", e)

        elif pilihan == '3':
            ser.close()
            break

        else:
            print("Pilihan invalid")

    elif pilihan == '2':
        ser.close()
        break

    else:
        print("Pilihan invalid")