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
