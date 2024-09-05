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

def test_methods_are_also_bound_to_a_function():
    obj = Class()
    print(obj.method())
    print(obj.method.__func__(obj))

# Remove hash below to activate function
#test_methods_are_also_bound_to_a_function()

def test_functions_have_attributes():
    obj = Class()
    print(len(dir(function)))
    print(dir(function) == dir(obj.method.__func__))

# Remove hash below to activate function
#test_functions_have_attributes()

def test_methods_have_different_attributes():
    obj = Class()
    print(len(dir(obj.method)))

# Remove hash below to activate function
#test_methods_have_different_attributes()

def test_setting_attributes_on_an_unbound_function():
    function.cherries = 3
    print(function.cherries)

# Remove hash below to activate function
#test_setting_attributes_on_an_unbound_function()

def test_setting_attributes_on_a_bound_method_directly():
    obj = Class()
    try:
        obj.method.cherries = 3
    except AttributeError as e:
        print(e)

# Remove hash below to activate function
#test_setting_attributes_on_a_bound_method_directly()

def test_setting_attributes_on_methods_by_accessing_the_inner_function():
    obj = Class()
    obj.method.__func__.cherries = 3
    print(obj.method.cherries)

# Remove hash below to activate function
#test_setting_attributes_on_methods_by_accessing_the_inner_function()

def test_functions_can_have_inner_functions():
    function2.get_fruit = function
    print(function2.get_fruit())

# Remove hash below to activate function
#test_functions_can_have_inner_functions()

def test_inner_functions_are_unbound():
    function2.get_fruit = function
    try:
        cls = function2.get_fruit.__self__
    except AttributeError as e:
        print(e)

# Remove hash below to activate function
test_inner_functions_are_unbound()

# ------------------------------------------------------------------
