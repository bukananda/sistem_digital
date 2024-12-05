import os

def create_text_file():
    print("Welcome to the TXT File Creator!")
    print("Note: Each line must be a maximum of 1000 ASCII characters.")
    
    # Ensure the 'chat' folder exists
    folder_name = "chat"
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)
    
    # Ask for file name
    file_name = input("Enter the name of the file (without .txt): ") + ".txt"
    
    # Full path for the file in the 'chat' folder
    file_path = os.path.join(folder_name, file_name)
    
    # Ask for the content of the file
    print("\nWrite your content below. When you're done, type 'END' on a new line and press Enter.")
    
    lines = []
    while True:
        line = input()
        if line.strip().upper() == "END":
            break
        
        # Check ASCII characters and limit to 64
        if not all(ord(c) < 128 for c in line):  # Check if all characters are ASCII
            print("Error: Only ASCII characters are allowed. Please try again.")
            continue
        
        if len(line) > 1000:
            print("Warning: Input exceeded 64 characters and will be truncated.")
            line = line[:1000]  # Truncate to 64 characters
        
        lines.append(line)
    
    # Save the content to the file
    try:
        with open(file_path, "w") as file:
            file.write("\n".join(lines))
        print(f"\nYour file '{file_name}' has been successfully created in the '{folder_name}' folder!")
    except Exception as e:
        print(f"An error occurred: {e}")

# Run the function
if __name__ == "__main__":
    create_text_file()
