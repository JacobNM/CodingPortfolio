def test_subfolders_can_form_part_of_a_module_package():
    # Import .Donalds Module/donald.py
    from donalds_module.donald import Duck

    duck = Duck()
    print(f"{duck.name == 'Donald'}. {duck.name} is a variable, which is the same value as {Duck().name}, which is an imported class method.")
    
# Remove hash to activate function
#test_subfolders_can_form_part_of_a_module_package()

def test_subfolders_become_modules_if_they_have_an_init_module():
    # Import .Donalds Module/__init__.py
    from donalds_module import an_attribute

    print(an_attribute)

# Remove hash to activate function
#test_subfolders_become_modules_if_they_have_an_init_module()

# ------------------------------------------------------------------

def test_use_absolute_imports_to_import_upper_level_modules():
    # Import /Python/Functions/local_module.py
    import local_module

    # Prints
    print(local_module.__name__)


# Remove hash to activate function
#test_use_absolute_imports_to_import_upper_level_modules()

def test_import_a_module_in_a_subfolder_folder_using_an_absolute_path():
    # Import /Python/Functions/local_module.py
    from Functions.donalds_module.donald import Duck

    print(Duck.__module__)

# Remove hash to activate function
test_import_a_module_in_a_subfolder_folder_using_an_absolute_path()