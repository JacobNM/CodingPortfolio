import os

# Define the path to your Obsidian tasks file
tasks_file = "/Users/jacob/My Drive/Obsidian Vaults/Obsidian - Personal Vault"

def ModifyFile(file_path):
    for root, dirs, files in os.walk(tasks_file):
        for file_name in files:
        # Only process markdown files
            if file_name.endswith(".md"):
                file_path = os.path.join(root, file_name)
                process_file(file_path)

# Loop through all files in the given folder
def process_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    for line in lines:
        # Check if the line is a task line (starting with - [ ] or - [x])
        if line.strip().startswith("- [ ]") or line.strip().startswith("- [x]"):
            # Split the line into text and tags
            parts = line.split("#")
            text = parts[0]
            tags = "#" + "#".join(parts[1:])

            # Append the tags to the end of the line
            line = text.strip() + " " + tags.strip() + "\n"

        modified_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(modified_lines)

    print(f"Processed: {file_path}")




print("Tags moved to the end of each task.")