class Dog:
    pass

def test_objects_are_objects():  
    fido = Dog()
    
    print(f"{isinstance(fido, object)}. {fido} is an object.")

# Remove hash below to activate function
#test_objects_are_objects()