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
# test_less_convoluted_matching_literal_text()

def test_matching_literal_text_how_many():
    """
        Lesson 3 -- How many matches?

        The default behaviour of most regular expression engines is
        to return just the first match. In python you have the
        following options:

            match()    -->  Determine if the RE matches at the
                            beginning of the string.
            search()   -->  Scan through a string, looking for any
                            location where this RE matches.
            findall()  -->  Find all substrings where the RE
                            matches, and return them as a list.
            finditer() -->  Find all substrings where the RE
                            matches, and return them as an iterator.
    """
    string = ("Hello, my name is Felix and these lessons are based " +
        "on a Python Koans exercise courtesy of Greg Malcolm. " +
        "Repeat My name is Felix")
    
    # Use re.match() to find the first occurrence of 'Felix' in the string
    # Match may not be the best option when looking for all occurrences of a pattern
    regex_match_meh = re.match('Felix', string)
    
    # What if I want to know how many times my name appears?
    print(regex_match_meh)
    # Huh? Why is the result None?
    # Because re.match() only looks for a match at the beginning of the string
    
    # Your solution:
    # Use re.findall() to find all occurrences of 'Felix' in the string
    regex_match_better = re.findall('Felix', string)
    
    # Print the occurrences of 'Felix' in the string in a list
    print("A list of occurrences of 'Felix' in the string: ", regex_match_better)
    # Get the number of occurrences of 'Felix' in the string
    no_of_occurrences = len(regex_match_better)
    # Print the number of occurrences of 'Felix' in the string
    print("Number of occurrences of 'Felix' in the string: ", no_of_occurrences)
    
# Remove hash below to activate function
# test_matching_literal_text_how_many()

def test_matching_literal_text_not_case_sensitivity():
    """
        Lesson 4 -- Matching Literal String non case sensitivity.
        Most regex implementations also support matches that are not
        case sensitive. In python you can use re.IGNORECASE, in
        Javascript you can specify the optional i flag.
    """
    string = "Hello, my name is Felix or felix and these lessons " + \
        "are based on a Python Koans exercise courtesy of Greg Malcolm."
    
    # Find all occurrences of 'felix' in the string
    # Case sensitive
    regex_match_case_sensitive = re.findall("felix", string)
    
    # Find all occurrences of 'felix' in the string
    # Case insensitive
    regex_match_case_insensitive = re.findall("felix", string, re.IGNORECASE)
    
    # Print the occurrences of 'felix' in the string in a list
    # Case sensitive
    print("Occurrences of 'felix' in the string (case sensitive): ", regex_match_case_sensitive)
    
    # Print the occurrences of 'felix' in the string in a list
    # Case insensitive
    print("Occurrences of 'felix' in the string (case insensitive): ", regex_match_case_insensitive)

# Remove hash below to activate function
# test_matching_literal_text_not_case_sensitivity()

def test_matching_any_character():
    """
        Lesson 5: Matching any character

        `.` matches any character: alphabetic characters, digits,
        and punctuation.
    """
    string = "pecks.xlx\n"    \
            + "orders1.xls\n" \
            + "apec1.xls\n"   \
            + "na1.xls\n"     \
            + "na2.xls\n"     \
            + "sa1.xls"
    
    # Find all occurrences of any character in the string
    regex_match_every_letter = re.findall(".", string)
    # Print the occurrences of any character in the string in a list
    print("Occurrences of any character in the string: ", regex_match_every_letter)
    
    # Find particular occurrences by combining '.' with text you want, such as 'a..xl'
    print("Occurrences of 'a..xlx' in the string: ", re.findall('a..xl', string))
    
# Remove hash below to activate function
test_matching_any_character()
