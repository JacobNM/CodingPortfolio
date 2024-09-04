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
test_init_method_is_the_constructor()

def test_private_attributes_are_not_really_private():
    dog = Dog2()
    dog.set_name("Fido")
    print(dog._name)
    # The _ prefix in _name implies private ownership, but nothing is truly
    # private in Python.

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

# ------------------------------------------------------------------

