import re

def rearrange_tags(task_line):
    # Extract tags from the beginning of the task line
    tags_match = re.match(r"^(#+\s*)?(\[\[.*?\]\]\s*)+", task_line)
    if tags_match:
        tags = tags_match.group(0).strip()
        task_without_tags = task_line[len(tags):].strip()
        return f"{task_without_tags} {tags}"
    return task_line

def process_file(file_path):
    with open(file_path, "r") as file:
        lines = file.readlines()

    modified_lines = []
    seen_tags = set()

    for line in lines:
        modified_line = rearrange_tags(line)
        modified_lines.append(modified_line)

        # Check for duplicate tags
        tags = re.findall(r"\[\[.*?\]\]", modified_line)
        for tag in tags:
            if tag in seen_tags:
                modified_lines.pop()  # Remove the line if duplicate tags found
                break
            seen_tags.add(tag)

    # Write modified content back to the file
    with open(file_path, "w") as file:
        file.writelines(modified_lines)

# Example usage:
obsidian_vault_file = "/path/to/your/obsidian/file.md"
process_file(obsidian_vault_file)
print("Tags rearranged and duplicates removed successfully!")
