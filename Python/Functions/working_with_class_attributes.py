class Dog:
    pass

def test_objects_are_objects():  
    fido = Dog()
    
    print(f"{isinstance(fido, object)}. {fido} is an object.")

# Remove hash below to activate function
#test_objects_are_objects()

def test_classes_are_types():
    print(f"{Dog.__class__ == type}. {Dog.__class__} is a type.")

# Remove hash below to activate function
#test_classes_are_types()

def test_classes_are_objects_too():
    print(f"{issubclass(Dog, object)}. {Dog} is a subclass of object.")

# Remove hash below to activate function
#test_classes_are_objects_too()

def test_objects_have_methods():
    fido = Dog()
    print(f"\nThere are {len(dir(fido))} methods in dir(fido). These methods are:\n")
    # While loop to print all methods in dir(fido) and number each incrementally
    method_count = 0
    while method_count < len(dir(fido)):
        print(f"{method_count + 1}. {dir(fido)[method_count]}")
        method_count += 1

# Remove hash below to activate function
#test_objects_have_methods()
