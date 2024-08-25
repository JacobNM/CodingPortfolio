import os
import re

# Set the path to your Obsidian vault
obsidian_vault_path = "/path/to/your/vault"

# Function to move tags from the beginning of the task to the end
def move_tags_in_task(task):
    # Regex to find tags at the beginning of the task
    match = re.match(r"^(\s*-\s\[\s*\]\s*)((#\S+\s+)+)(.+)", task)
    if match:
        prefix = match.group(1)  # Task checkbox and leading spaces
        tags = match.group(2)  # Tags at the beginning
        content = match.group(4)  # The actual task content without the initial tags
        # Rebuild the task with tags at the end
        new_task = f"{prefix}{content.strip()} {tags.strip()}\n"
        return new_task
    return task

# Function to process all markdown files in the vault
def process_files_in_vault(vault_path):
    for root, dirs, files in os.walk(vault_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                process_file(file_path)
                print(f"Processing: {file_path}")
                print("Done!")

# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    modified_lines = []
    modified = False
    for line in lines:
        if line.strip().startswith("- [ ]"):  # Identify tasks, both complete and incomplete
            new_line = move_tags_in_task(line)
            modified_lines.append(new_line)
            if new_line != line:
                modified = True
        else:
            modified_lines.append(line)
    
    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(modified_lines)
            

# Process the files in the vault
process_files_in_vault(obsidian_vault_path)