import re

def test_convoluted_matching_literal_text():
    """
        Lesson 1 Matching Literal String
    """
    string = "Hello, my name is Felix and these lessons are based " + \
    "on a Python Koans exercise courtesy of Greg Malcolm."
    
    # Search for the word 'Felix' in the string
    regex_match = re.search('Felix', string)
    
# A simple, but rather convoluted way to check if the match is found
    # print(regex_match and regex_match.group(0) and
    #     regex_match.group(0) == 'Felix',
    #     "I want my name"
    #     )
    
# A more concise way to check if the match is found
# Offers the ability to add custom messages
    print(
        "Checking for match...",
        f"\n{regex_match and regex_match.group(0) and regex_match.group(0) == 'Felix'}",
        f"Match for search was found: {regex_match.group(0)}")
    
# Remove hash below to activate function
# test_convoluted_matching_literal_text()

def test_less_convoluted_matching_literal_text():
    """
        Lesson 2 Matching Literal String in a simpler way
    """
    string = "Hello, my name is Felix and these lessons are based " + \
    "on a Python Koans exercise courtesy of Greg Malcolm."
    
    # Search for the word 'Felix' in the string
    regex_match = re.search('Felix', string)
    
    # Check if the match is found
    if regex_match:
        # Get the matched text
        matched_text = regex_match.group(0)
        # Check if the matched text is 'Felix' and assign the result to is_match
        is_match = matched_text == 'Felix'
    else:
        # If no match is found, assign False to is_match
        is_match = False

    print("Checking for match...",
        f"\n{is_match}",
        f'Match for search was found: {matched_text}')

# Remove hash below to activate function
test_less_convoluted_matching_literal_text()

