import os

def append_tag_to_tasks(folder_path, tag="#task"):
    # Loop through all files in the given folder
    for root, dirs, files in os.walk(folder_path):
        for file_name in files:
            # Only process markdown files
            if file_name.endswith(".md"):
                file_path = os.path.join(root, file_name)
                process_file(file_path, tag)

def process_file(file_path, tag):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    for line in lines:
        # Check if the line is a task line (starting with - [ ] or - [x])
        if line.strip().startswith("- [ ]") or line.strip().startswith("- [x]"):
            # Only append the tag if it's not already present
            if tag not in line:
                line = line.strip() + " " + tag + "\n"
        modified_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(modified_lines)
    
    print(f"Processed: {file_path}")
    
print("Done!")

# Replace this with the path to your Obsidian vault folder
obsidian_folder_path = "/path/to/your/obsidian/vault"
append_tag_to_tasks(obsidian_folder_path)