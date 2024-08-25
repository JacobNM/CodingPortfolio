import re
import os

# Replace this with the path to the folder containing your markdown files
folder_path = "/path/to/your/folder"

# Function to process all markdown files in a folder
def process_files_in_folder(folder_path):
    print(f"Processing files in folder: {folder_path}\n")
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                process_file(file_path)
                # Additional code to detect strikethrough in completed Obsidian tasks
                with open(file_path, 'r', encoding='utf-8') as f:
                    file_content = f.read()
                completed_tasks = re.findall(r"- \[x\] (.*?)\n", file_content)
                if completed_tasks:
                    print(f"Detected tasks with strikethrough in {file_path}:")
                    print(f"{completed_tasks}\n")

    print("Done!")                
                
# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        files = f.readlines()

# Activate the function to process the files in the folder
process_files_in_folder(folder_path)