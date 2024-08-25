import re
import os

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
                    print(completed_tasks)

# Function to move tags from the beginning of the task to the end
def move_tags_in_task(task):
    # Regex to find tags at the beginning of complete tasks
    match = re.match(r"^(\s*~~- \[x\]~~\s*)((#\S+\s+)+)(.+)", task) # Completed tasks with strikethrough
    if match:
        prefix = match.group(1)
        tags = match.group(2)
        content = match.group(4)
        new_task = f"{prefix}{content.strip()} {tags.strip()}\n"
        return new_task
                    
                
    print("Done!")                
                
# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        file_content = f.readlines()
    
# Replace this with the path to the folder containing your markdown files
folder_path = "/path/to/your/folder"

process_files_in_folder(folder_path)            