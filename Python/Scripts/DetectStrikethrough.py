import re
import os

def detect_strikethrough(file):
    # Regex to find strikethrough text in markdown (~~text~~)
    strikethrough_pattern = r"~~(.*?)~~"
    matches = re.findall(strikethrough_pattern, file)
    return matches

# Function to process all markdown files in a folder
def process_files_in_folder(folder_path):
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                process_file(file_path)
                print(f"Processing: {file_path}")
                print("Done!")
                
# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        file_content = f.read()
    
    strikethrough_matches = detect_strikethrough(file_content)
    if strikethrough_matches:
        print(f"Strikethrough text found in {file_path}:")
        for match in strikethrough_matches:
            print(match)
        print("\n")
    else:
        print(f"No strikethrough text found in {file_path}\n")
            
    
# Replace this with the path to the folder containing your markdown files
folder_path = "/path/to/your/markdown/files"

process_files_in_folder(folder_path)            