import re # For regular expression string comparisons


def count_lines(file_path):
    # Path to file
    #path = "Python/Examples/example_file.txt"
    try:
        with open(file_path) as file:
            return len(file.readlines())
    except IOError:
        # should never happen
        print(IOError)
        return 0
    finally:
        file.close()

def test_counting_lines():
    print(count_lines("Python/Examples/example_file.txt"))

# Remove hash below to activate function
#test_counting_lines()

# ------------------------------------------------------------------

def find_line(file_path):
    try:
        file = open(file_path)
        try:
            for line in file.readlines():
                match = re.search('h', line)
                if match:
                    return line
        finally:
            file.close()
    except IOError:
        # should never happen
        print(IOError)
        return 0

def test_finding_lines():
    print(find_line("Python/Examples/example_file.txt"))
  
# Remove hash below to activate function
#test_finding_lines()

  
 ## The count_lines and find_line are similar, and yet different.
    ## They both follow the pattern of "sandwich code".
    ##
    ## Sandwich code is code that comes in three parts: (1) the top slice
    ## of bread, (2) the meat, and (3) the bottom slice of bread.
    ## The bread part of the sandwich almost always goes together, but
    ## the meat part changes all the time.
    ##
    ## Because the changing part of the sandwich code is in the middle,
    ## abstracting the top and bottom bread slices to a library can be
    ## difficult in many languages.
    ##
    ## (Aside for C++ programmers: The idiom of capturing allocated
    ## pointers in a smart pointer constructor is an attempt to deal with
    ## the problem of sandwich code for resource allocation.)
    ##
    ## Python solves the problem using Context Managers. Consider the
    ## following code:

class FileContextManager():
    def __init__(file_path):
        file_path = file_path
        file = None

    def __enter__(file_path):
        file = open(file_path)
        return file

    def __exit__(file, cls, value, tb):
        file.close()

def count_lines2(file_path):
    with FileContextManager(file_path) as file:
        return len(file.readlines())
    
def test_counting_lines2():
    print(count_lines2("Python/Examples/example_file.txt"))

# Remove hash below to activate function
test_counting_lines2()