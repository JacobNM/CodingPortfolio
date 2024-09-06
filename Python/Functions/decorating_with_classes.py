import functools

def maximum(a, b):
    if a>b:
        return a
    else:
        return b
    
def test_partial_that_wrappers_no_args():
    """
    Before we can understand this type of decorator we need to consider
    the partial.
    """
    max = functools.partial(maximum)

    print(max(7,23))
    print(max(10,-10))
    
# Remove hash below to activate function
#test_partial_that_wrappers_no_args()

def test_partial_that_wrappers_first_arg():
    max0 = functools.partial(maximum, 0)

    print(max0(-4))
    print(max0(5))

# Remove hash below to activate function
#test_partial_that_wrappers_first_arg()

def test_partial_that_wrappers_all_args():
    always99 = functools.partial(maximum, 99, 20)
    always20 = functools.partial(maximum, 9, 20)

    print(always99())
    print(always20())

# Remove hash below to activate function
#test_partial_that_wrappers_all_args()

# ------------------------------------------------------------------

class doubleit:
    def __init__(self, fn):
        self.fn = fn

    def __call__(self, *args):
        return self.fn(*args) + ', ' + self.fn(*args)

    def __get__(self, obj, cls=None):
        if not obj:
            # Decorating an unbound function
            return self
        else:
            # Decorating a bound method
            return functools.partial(self, obj)

@doubleit
def foo():
    return "foo"

@doubleit
def parrot(text):
    return text.upper()

def test_deorator_with_no_args():
    # To clarify: the decorator above the function has no arguments, even
    # if the decorated function does
    print(foo())
    print(parrot("pieces of eight"))
    
# Remove hash below to activate function
#test_deorator_with_no_args()

# ------------------------------------------------------------------

def sound_check():
    #Note: no decorator
    return "Testing..."

#@doubleit
def test_what_a_decorator_is_doing_to_a_function():
   
    #wrap the function with the decorator
    sound_check_decorated = doubleit(sound_check)
    #sound_check = doubleit(sound_check)
    print(sound_check_decorated())


# Remove hash below to activate function
#test_what_a_decorator_is_doing_to_a_function()

# ------------------------------------------------------------------
