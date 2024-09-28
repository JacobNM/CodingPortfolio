import re

def test_matching_literal_text():
    """
        Lesson 1 Matching Literal String
    """
    string = "Hello, my name is Felix and these lessons are based " + \
    "on Ben's book: Regular Expressions in 10 minutes."
    regex_match = re.search('Felix', string)
    
    print(
        regex_match and regex_match.group(0) and
        regex_match.group(0) == 'Felix',
        "I want my name")
    # assert m and m.group(0) and m.group(0) == 'Felix', "I want my name"
    
# Remove hash below to activate function
test_matching_literal_text()