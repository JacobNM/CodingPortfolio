class Dog:
    "Dogs need regular walkies. Never, ever let them drive."

def test_instances_of_classes_can_be_created_adding_parentheses():
    # NOTE: The .__name__ attribute will convert the class
    # into a string value.
    fido = Dog()
    print(fido.__class__.__name__)

# Remove hash below to activate function
#test_instances_of_classes_can_be_created_adding_parentheses()

def test_classes_have_docstrings():
    print(Dog.__doc__)

# Remove hash below to activate function
#test_classes_have_docstrings()

# ------------------------------------------------------------------

class Dog2:
    def __init__(Dog2):
        Dog2._name = 'Paul'

    def set_name(Dog2, a_name):
        Dog2._name = a_name

def test_init_method_is_the_constructor():
    dog = Dog2()
    print(dog._name)

# Remove hash below to activate function
#test_init_method_is_the_constructor()

def test_private_attributes_are_not_really_private():
    dog = Dog2()
    dog.set_name("Fido")
    print(dog._name)
    # The _ prefix in _name implies private ownership, but nothing is truly
    # private in Python.

# Remove hash below to activate function
#test_private_attributes_are_not_really_private()

def test_you_can_also_access_the_value_out_using_getattr_and_dict():
    fido = Dog2()
    fido.set_name("Fido")

    print(getattr(fido, "_name"))
    # getattr(), setattr() and delattr() are a way of accessing attributes
    # by method rather than through assignment operators

    print(fido.__dict__["_name"])
    # Yes, this works here, but don't rely on the __dict__ object! Some
    # class implementations use optimization which result in __dict__ not
    # showing everything.

# Remove hash below to activate function
#test_you_can_also_access_the_value_out_using_getattr_and_dict()

# ------------------------------------------------------------------

class Dog3:
    def __init__(Dog3):
        Dog3._name = None
        
    def set_name(Dog3, a_name):
        Dog3._name = a_name
        
    def get_name(Dog3):
        return Dog3._name
    
    name = property(get_name, set_name)
    
def test_that_name_can_be_read_as_a_property():
    fido = Dog3()
    fido.set_name("Fido")

    # access as method
    print(fido.get_name())

    # access as property
    print(fido.name)
    
# Remove hash below to activate function
#test_that_name_can_be_read_as_a_property()

# ------------------------------------------------------------------

class Dog4:
    def __init__(Dog4):
        Dog4._name = None

    @property
    def name(Dog4):
        return Dog4._name
    
    @name.setter
    def name(Dog4, a_name):
        Dog4._name = a_name
        
def test_creating_properties_with_decorators_is_slightly_easier():
    fido = Dog4()

    fido.name = "Fido"
    print(fido.name)

# Remove hash below to activate function
#test_creating_properties_with_decorators_is_slightly_easier()

# ------------------------------------------------------------------

class Dog5:
    def __init__(Dog5, initial_name):
        Dog5._name = initial_name

    @property
    def name(Dog5):
        return Dog5._name
    
def test_init_provides_initial_values_for_instance_variables():
    fido = Dog5("Fido")
    print(fido.name)

# Remove hash below to activate function
#test_init_provides_initial_values_for_instance_variables()

def test_args_must_match_init():
    try:
        fido = Dog5() # This will not work. Remove hash at beginning to try it out.
        #fido = Dog5("Rupert") # This will work. Remove hash at beginning to try it out.
        print(fido.name)
    except TypeError as ex:
        print(ex)

# Remove hash below to activate function
#test_args_must_match_init()

def test_different_objects_have_different_instance_variables():
    fido = Dog5("Fido")
    rover = Dog5("Rover")
    print(fido.name)
    print(rover.name)
    print(rover.name == fido.name)

# Remove hash below to activate function
#test_different_objects_have_different_instance_variables()

# ------------------------------------------------------------------

class Dog6:
    def __init__(pup, initial_name):
        pup._name = initial_name

    def get_self(pup):
        return pup
    
    def __str__(pup):
        return pup._name
    
    def __repr__(pup):
        return "<Dog named '" + pup._name + "'>"
    
def test_inside_a_method_self_refers_to_the_containing_object():
    # Function will return "<Dog named 'Fido'>"
    fido = Dog6("Fido")
    print(fido.get_self())
    
# Remove hash below to activate function
#test_inside_a_method_self_refers_to_the_containing_object()

def test_str_provides_a_string_version_of_the_object():
    fido = Dog6("Milo")
    print(str(fido))

# Remove hash below to activate function
#test_str_provides_a_string_version_of_the_object()

def test_str_is_used_explicitly_in_string_interpolation():
    fido = Dog6("Pluto")
    print(f"My dog is " + str(fido))

# Remove hash below to activate function
#test_str_is_used_explicitly_in_string_interpolation()

def test_repr_provides_a_string_representation_of_the_object():
    fido = Dog6("Clifford")
    print(repr(fido))
    
# Remove hash below to activate function
#test_repr_provides_a_string_representation_of_the_object()

def test_all_objects_support_str_and_repr():
    seq = [1, 2, 3]
    
    print(str(seq))
    print(repr(seq))
    
    print(str("STRING"))
    print(repr("STRING"))

# Remove hash below to activate function
#test_all_objects_support_str_and_repr()