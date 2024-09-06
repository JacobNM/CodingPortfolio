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
