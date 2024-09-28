import random

# Greed is a dice game where you roll up to five dice to accumulate
# points.  The following "score" function will be used to calculate the
# score of a single roll of the dice.
#
# A greed roll is scored as follows:
#
# * A set of three ones is 1000 points
#
# * A set of three numbers (other than ones) is worth 100 times the
#   number. (e.g. three fives is 500 points).
#
# * A one (that is not part of a set of three) is worth 100 points.
#
# * A five (that is not part of a set of three) is worth 50 points.
#
# * Everything else is worth 0 points.
#
# Examples:
#
# score([1,1,1,5,1]) => 1150 points
# score([2,3,4,6,2]) => 0 points
# score([3,4,5,3,3]) => 350 points
# score([1,5,1,2,4]) => 250 points
#
# More scoring examples are given in the tests below:

# Create a class to represent a set of dice
class DiceSet:
    def __init__(self):
        self._values = None

    @property
    def values(self):
        return self._values

    def roll(self, n):
        # Generate random numbers for n dice
        self._values = [random.randint(1, 6) for _ in range(n)]
        pass

class Player:
    def __init__(self, name):
        self.name = name
        self.score = 0
    
    def __str__(self):
        return self.name
    
    def __repr__(self):
        return self.name
    
    def play(self):
        dice = DiceSet()
        dice.roll(5)
        self.score += score(dice.values)
        return self.score
    
    def reset(self):
        self.score = 0
        
class Game:
    def __init__(self, players):
        self.players = players
        self.current_player = 0
        self.winner = None
    
    def play_round(self):
        for player in self.players:
            player.play()
            if player.score >= 3000:
                self.winner = player
                break
        return self.winner
    
    def play_game(self):
        while not self.winner:
            self.play_round()
        return self.winner
    
    def reset(self):
        for player in self.players:
            player.reset()
        self.winner = None
    
    def __str__(self):
        return f"Game with {len(self.players)} players"
    
    def __repr__(self):
        return f"Game with {len(self.players)} players"

# Function to calculate the score of dice rolls
def score(dice):
    score = 0
    counts = [0] * 7

    for die in dice:
        counts[die] += 1

    for i in range(1, 7):
        if counts[i] >= 3:
            if i == 1:
                score += 1000
            else:
                score += i * 100
            counts[i] -= 3

    score += counts[1] * 100
    score += counts[5] * 50

    return score
