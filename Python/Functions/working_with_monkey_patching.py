class Dog:
    def bark(self):
        return "WOOF"

def test_as_defined_dogs_do_bark():
    fido = Dog()
    print(fido.bark())

# Remove hash below to activate function
#test_as_defined_dogs_do_bark()

# ------------------------------------------------------------------

# Add a new method to an existing class.
def test_after_patching_dogs_can_both_wag_and_bark():
    def wag(self): return "HAPPY"
    Dog.wag = wag

    fido = Dog()
    print(fido.wag())
    print(fido.bark())

# Remove hash to activate function
#test_after_patching_dogs_can_both_wag_and_bark()

# ------------------------------------------------------------------

def test_most_built_in_classes_cannot_be_monkey_patched():
    try:
        int.is_even = lambda self: (self % 2) == 0
    except Exception as ex:
        err_msg = ex.args[0]

    print(err_msg)

# Remove hash to activate function
#test_most_built_in_classes_cannot_be_monkey_patched()

# ------------------------------------------------------------------

class MyInt(int): pass

def test_subclasses_of_built_in_classes_can_be_be_monkey_patched():
    MyInt.is_even = lambda self: (self % 2) == 0

    print(MyInt(1).is_even())
    print(MyInt(2).is_even())

# Remove hash to activate function
#test_subclasses_of_built_in_classes_can_be_be_monkey_patched()