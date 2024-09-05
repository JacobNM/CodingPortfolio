def function():
    return "pineapple"

def function2():
    return "tractor"

class Class:
    def method(self):
        return "parrot"
    
def test_methods_are_bound_to_an_object():
    obj = Class()
    print(obj.method.__self__ == obj)
    
# Remove hash below to activate function
#test_methods_are_bound_to_an_object()