import os
import re

# Set the path to your Obsidian vault
obsidian_vault_path = "/path/to/your/vault"

# Function to process all markdown files in the vault
def process_files_in_vault(vault_path):
    print(f"\nProcessing files in '{vault_path}' for incomplete tasks:\n\n")
    for root, dirs, files in os.walk(vault_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                process_file(file_path)
    print("Done!\n\n")

# Function to process each individual file
def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    # Process each line in the file. If a task is found, move the tags to the end
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

# Function to move tags from the beginning of the task to the end
def move_tags_in_task(task):
    # Regex to find tags at the beginning of the task
    match = re.match(r"^(\s*-\s\[\s*\]\s*)((#\S+\s+)+)(.+)", task)
    if match:
        print(f"Detected incomplete task: {task}")
        print("Modifying task...")
        prefix = match.group(1)  # Task checkbox and leading spaces
        tags = match.group(2)  # Tags at the beginning
        content = match.group(4)  # The actual task content without the initial tags
        # Rebuild the task with tags at the end
        new_task = f"{prefix}{content.strip()} {tags.strip()}\n"
        print(f"Modified task: {new_task}\n")
        return new_task
    return task

# Function to process all strikethrough files in a vault folder
def process_strikethrough_files_in_vault(folder_path):
    print(f"Processing files in '{folder_path}' for completed tasks:\n")
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".md"):
                file_path = os.path.join(root, file)
                process_file(file_path)
                # Detect strikethrough in completed Obsidian tasks
                with open(file_path, 'r', encoding='utf-8') as f:
                    file_content = f.read()
                completed_tasks = re.findall(r"- \[x\] (.*?)\n", file_content)
                if completed_tasks:
                    print(f"\nDetected completed tasks in {file_path}:")
                    print(f"{completed_tasks}\n")
                    print("Modifying tasks...")
                    # If completed task starts with a tag, move the tag to the end
                    for task in completed_tasks:
                        match = re.match(r"((#\S+\s+)+)(.+)", task)
                        if match:
                            tags = match.group(1) # Tags at the beginning
                            content = match.group(3) # The actual task content without the initial tags
                            new_task = f"{content.strip()} {tags.strip()}"
                            print(f"Modified task: {new_task}\n")
                            # Write the modified task back to the file
                            with open(file_path , 'r', encoding='utf-8') as f:
                                file_content = f.read()
                            file_content = file_content.replace(f"- [x] {task}", f"- [x] {new_task}")
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(file_content)
    print("\nDone!")
# Process the files in the vault
process_files_in_vault(obsidian_vault_path)
process_strikethrough_files_in_vault(obsidian_vault_path)