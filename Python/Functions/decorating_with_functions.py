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
