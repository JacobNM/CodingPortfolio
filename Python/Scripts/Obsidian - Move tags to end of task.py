import os

# Define the path to your Obsidian tasks file
tasks_file = "/Users/jacob/My Drive/Obsidian Vaults/Obsidian - Personal Vault"

# Loop through all files in the given folder
for root, dirs, files in os.walk(tasks_file):
    for file_name in files:
        # Only process markdown files
        if file_name.endswith(".md"):
            file_path = os.path.join(root, file_name)
            process_file(file_path)



print("Tags moved to the end of each task.")