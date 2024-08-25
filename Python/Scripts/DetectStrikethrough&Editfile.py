import re
import os

# Replace this with the path to the folder containing your markdown files
folder_path = "/Users/jacob/My Drive/Obsidian Vaults/Obsidian - Personal Vault"

# Function to process all strikethrough files in a vault folder
def process_strikethrough_files_in_vault(folder_path):
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
                    # If completed task starts with a tag, move the tag to the end
                    for task in completed_tasks:
                        match = re.match(r"((#\S+\s+)+)(.+)", task)
                        if match:
                            tags = match.group(1) # Tags at the beginning
                            content = match.group(3) # The actual task content without the initial tags
                            new_task = f"{content.strip()} {tags.strip()}"
                            print(f"Modified task: {new_task}")
                            # Write the modified task back to the file
                            with open(file_path , 'r', encoding='utf-8') as f:
                                file_content = f.read()
                            file_content = file_content.replace(f"- [x] {task}", f"- [x] {new_task}")
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(file_content)                             
                        
    print("Done!")                
                
# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        files = f.readlines()

# Activate the function to process the files in the folder
process_strikethrough_files_in_vault(folder_path)