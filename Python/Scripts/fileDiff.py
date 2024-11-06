import difflib

# Example strings to compare
# string1 = "437f1a3ed3e04601d0f52914251c61b4-bob"
# string2 = "437f1a3ed3e04601d0f52914251c61b4"

string1 = "<insert string here>"
string2 = "<insert string here>"

diff = difflib.ndiff(string1, string2)
diffs = [line[2:] for line in diff if line.startswith('-') or line.startswith('+')]
print(' '.join(diffs))
