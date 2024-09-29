import os
import random

# Greed is a dice game where you roll up to five dice to accumulate
# points.  The following "score" function will be used to calculate the
# score of a single roll of the dice.
#
# A greed roll is scored as follows:
# * A set of three ones is 1000 points
# * A set of three numbers (other than ones) is worth 100 times the
#   number. (e.g. three fives is 500 points).
# * A one (that is not part of a set of three) is worth 100 points.
# * A five (that is not part of a set of three) is worth 50 points.
# * Everything else is worth 0 points.

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
        self.total_score = 0
    
    def __str__(self):
        return self.name
    
    def __repr__(self):
        return self.name
    
    def play(self):
        dice = DiceSet()
        dice.roll(5)
        self.score += score(dice.values)
        self.total_score += self.score
        return self.score
    
    def reset(self):
        self.score = 0
        self.total_score = 0
        
class Game:
    def __init__(self, players):
        self.players = players
        self.current_player = 0
        self.winner = None
    
    def num_players(self):
        return len(self.players)
    
    def num_rounds(self):
        rounds = 0
        while not self.winner:
            self.play_round()
            rounds += 1
        return rounds    

    def play_game(self):
        while not self.winner:
            for player in self.players:
                player.play()
                if player.total_score >= 3000:
                    self.winner = player
                    break
        return self.winner
    
    def track_total_scores(self):
            return {player.name: player.total_score for player in self.players}
    
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

def play_quick_greed_game():
    # Welcome message and game instructions
    print("\nWelcome to Greed!",
        "\nThe game is simple. Each player will roll 5 dice and try to accumulate points.",
        "\n\nScoring is as follows:",
        "\n\t- A set of three ones is 1000 points",
        "\n\t- A set of three fives is 500 points",
        "\n\t- A set of three numbers (other than ones and fives) is worth 100 times the number. (e.g. three fives is 500 points).",
        "\n\t- A one (that is not part of a set of three) is worth 100 points.",
        "\n\t- A five (that is not part of a set of three) is worth 50 points.",
        "\n\t- Everything else is worth 0 points.",
        "\n\nLet's play!\n"
          )
    input("\nPress Enter to start the game...")
    
    # Clear screen and start the game
    os.system('cls' if os.name == 'nt' else 'clear')
    
    # Determine the number of players
    num_players = int(input("\nHow many players are playing? "))
    
    # Name and create the players
    player_names = []
    for player in range(num_players):
        player_names.append(input(f"\nGreat! Player {player + 1}, what is your name? "))
    players = [Player(name) for name in player_names]
    
    # Play the game
    game = Game(players)
    winner = game.play_game()
    print(f"The winner is {str(winner)} with a score of {str(winner.score)}")
    
# Remove the comment below to play the quick version of the game
# play_quick_greed_game()

def play_greed_game_in_turns():
    # Welcome message and game instructions
    print("\nWelcome to Greed!",
        "\nThe game is simple. Each player will roll 5 dice and try to accumulate points.",
        "\n\nScoring is as follows:",
        "\n\t- A set of three ones is 1000 points",
        "\n\t- A set of three fives is 500 points",
        "\n\t- A set of three numbers (other than ones and fives) is worth 100 times the number. (e.g. three fives is 500 points).",
        "\n\t- A one (that is not part of a set of three) is worth 100 points.",
        "\n\t- A five (that is not part of a set of three) is worth 50 points.",
        "\n\t- Everything else is worth 0 points.",
        "\n\nThe first player to reach 3000 points wins the game.",
        "\n\nLet's play!\n"
          )
    input("\nPress Enter to start the game...")
    
    # Clear screen and start the game
    os.system('cls' if os.name == 'nt' else 'clear')
    
    # Determine the number of players
    num_players = int(input("\nHow many players are playing? "))
    
    # Name and create the players
    player_names = []
    for player in range(num_players):
        player_names.append(input(f"\nGreat! Player {player + 1}, what is your name? "))
    players = [Player(name) for name in player_names]
        
    # Play the game
    game = Game(players)
    while not game.winner:
        for player in players:
            print(f"\n{player.name}'s turn:")
            input("Press Enter to roll the dice...")
            player.play()
            print(f"{player.name} rolled {player.score} points this turn.")
            if player.total_score >= 3000:
                game.winner = player
                break
            print(f"Current scores: {game.track_total_scores()}")
            input("Press Enter to continue to the next player...")
            os.system('cls' if os.name == 'nt' else 'clear')
    winner = game.play_game()
    
    print(f"The winner is {game.winner.name} with a score of {game.track_total_scores()[game.winner.name]}")
    
# Remove the comment below to play the game
play_greed_game_in_turns()