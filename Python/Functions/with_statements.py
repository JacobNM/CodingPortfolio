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
    def __init__(self, file_path):
        self._file_path = file_path
        self._file = None

    def __enter__(self):
        self._file = open(self._file_path)
        return self._file

    def __exit__(self, cls, value, tb):
        self._file.close()

def count_lines2(file_path):
    with FileContextManager(file_path) as file:
        return len(file.readlines())
    
def test_counting_lines2():
    print(count_lines2("Python/Examples/example_file.txt"))

# Remove hash below to activate function
#test_counting_lines2()

# ------------------------------------------------------------------

def find_line2(file_path):
    with FileContextManager(file_path) as file:
        for line in file.readlines():
            match = re.search('e', line)
            if match:
                return line

def test_finding_lines2():
    print(find_line2("Python/Examples/example_file.txt"))

# Remove hash below to activate function
#test_finding_lines2()

# ------------------------------------------------------------------

def count_lines3(file_path):
    with open(file_path) as file:
        return len(file.readlines())
    
def test_open_already_has_its_own_built_in_context_manager():
    print(count_lines3("Python/Examples/example_file.txt"))

# Remove hash below to activate function
#test_open_already_has_its_own_built_in_context_manager()

# ------------------------------------------------------------------

# Next find_line3 function will find all lines containing the letter 'e'

def find_line3(file_path):
    with open(file_path) as file:
        for line in file.readlines():
            match = re.search('e', line)
            if match:
                print(line)

def test_finding_lines3():
    find_line3("Python/Examples/example_file.txt")

# Remove hash below to activate function
#test_finding_lines3()