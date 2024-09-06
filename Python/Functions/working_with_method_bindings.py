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
#test_inner_functions_are_unbound()

# ------------------------------------------------------------------

class BoundClass:
    def __get__(self, obj, cls):
        return (self, obj, cls)

binding = BoundClass()

def test_get_descriptor_resolves_attribute_binding():
    #bound_obj, binding_owner, owner_type = binding
    # Look at BoundClass.__get__():
    #   bound_obj = self
    #   binding_owner = obj
    #   owner_type = cls
    
    print(BoundClass.__get__(binding, None, None))
    
    #print(bound_obj.__class__.__name__)
    #print(binding_owner.__class__.__name__)
    #print(owner_type.__name__)

# Remove hash below to activate function
#test_get_descriptor_resolves_attribute_binding()

# ------------------------------------------------------------------

class SuperColor:
    def __init__(self):
        self.choice = None
    
    def __set__(self, obj, val):
        self.choice = val

color = SuperColor()

def test_set_descriptor_changes_behavior_of_attribute_assignment():
    
    try:
        if color.choice == None:
            print(f"Error: color.choice is currently set to None")
        else:
            print(f"color.choice is {(color.choice)}")
    except UnboundLocalError as e:
        print(e)
    
    color.__set__(color, "blue")
    print(f"Color is set to {(color.choice)}")

# Remove hash below to activate function
#test_set_descriptor_changes_behavior_of_attribute_assignment()