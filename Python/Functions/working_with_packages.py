def test_subfolders_can_form_part_of_a_module_package():
    # Import .Donalds Module/donald.py
    from donalds_module.donald import Duck

    duck = Duck()
    print(f"{duck.name == 'Donald'}. {duck.name} is a variable, which is the same value as {Duck().name}, which is an imported class method.")
    
# Remove hash to activate function
#test_subfolders_can_form_part_of_a_module_package()
