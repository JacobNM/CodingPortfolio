def addcowbell(fn):
        fn.wow_factor = 'COWBELL BABY!'
        return fn
@addcowbell
def mediocre_song():
    return "o/~ We all live in a broken submarine o/~"

def test_decorators_can_modify_a_function():
    print(mediocre_song())
    print(mediocre_song.wow_factor)

# Remove hash below to activate function
#test_decorators_can_modify_a_function()

# ------------------------------------------------------------------

def xmltag(fn):
    def func(*args):
        return '<' + fn(*args) + '/>'
    return func

@xmltag
def render_tag(name):
    return name

def test_decorators_can_change_a_function_output():
    print(render_tag('llama'))
    
# Remove hash below to activate function
#test_decorators_can_change_a_function_output()