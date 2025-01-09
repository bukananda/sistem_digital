import serial
import time

# Konfigurasi port serial
port = "COM3"  # Ganti dengan port serial yang sesuai
baudrate = 9600  # Ganti dengan baud rate yang sesuai

# Inisialisasi objek serial
ser = serial.Serial(port, baudrate, timeout=5)

# String data yang akan dikirim
while True:
    pilihan = input("\n1. Masukkan input: \n2. Keluar: \n")
    if pilihan == '1':
        data_tx = input("Masukkan plain text: ")

        # data_tx = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

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

    elif pilihan == '2':
        ser.close()
        break

    else:
        print("Pilihan invallid")