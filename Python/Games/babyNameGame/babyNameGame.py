#!/usr/bin/env python3
"""
Baby Name Ranking Game

A game to help couples sort through their favorite baby names by ranking them
in groups of three. Each name receives points based on rankings, and final
results show the most preferred names.

Author: Jacob
Date: January 2026
"""

import random
import json
from typing import List, Dict, Tuple


class BabyNameGame:
    def __init__(self):
        self.names = []
        self.scores = {}
        self.used_names = set()
        self.round_number = 0
        
    def load_names_from_input(self) -> None:
        """Load baby names from user input."""
        print("🍼 Welcome to the Baby Name Ranking Game! 🍼")
        print("=" * 50)
        print("This game will help you and your partner rank baby names.")
        print("You'll see 3 names at a time and pick your 1st and 2nd favorites.")
        print("Names get points: 3 for 1st place, 1 for 2nd place, 0 for 3rd place")
        print()
        
        while True:
            print("How would you like to input your names?")
            print("1. Type them one by one")
            print("2. Enter them all at once (comma-separated)")
            print("3. Load from a file (names.txt)")
            
            choice = input("\nChoose option (1-3): ").strip()
            
            if choice == "1":
                self._input_names_individually()
                break
            elif choice == "2":
                self._input_names_bulk()
                break
            elif choice == "3":
                if self._load_names_from_file():
                    break
                else:
                    print("File not found. Please choose another option.\n")
            else:
                print("Please enter 1, 2, or 3.\n")
    
    def _input_names_individually(self) -> None:
        """Input names one by one."""
        print("\nEnter baby names one by one. Press Enter with no name to finish:")
        while True:
            name = input(f"Name #{len(self.names) + 1}: ").strip()
            if not name:
                if len(self.names) < 3:
                    print("Please enter at least 3 names to play the game.")
                    continue
                else:
                    break
            if name not in self.names:
                self.names.append(name)
                self.scores[name] = 0
            else:
                print("Name already exists, please enter a different name.")
    
    def _input_names_bulk(self) -> None:
        """Input all names at once, comma-separated."""
        print("\nEnter all names separated by commas:")
        names_input = input("Names: ").strip()
        
        if names_input:
            names_list = [name.strip() for name in names_input.split(",")]
            names_list = [name for name in names_list if name]  # Remove empty strings
            
            for name in names_list:
                if name not in self.names:
                    self.names.append(name)
                    self.scores[name] = 0
        
        if len(self.names) < 3:
            print("Please enter at least 3 names. Let's try again.")
            self.names.clear()
            self.scores.clear()
            self._input_names_bulk()
    
    def _load_names_from_file(self) -> bool:
        """Load names from a text file."""
        print("\nEnter the file path (or press Enter for default 'names.txt'):")
        file_path = input("File path: ").strip()
        
        if not file_path:
            file_path = "names.txt"
        
        try:
            with open(file_path, "r") as file:
                for line in file:
                    name = line.strip()
                    if name and name not in self.names:
                        self.names.append(name)
                        self.scores[name] = 0
            
            if len(self.names) < 3:
                print(f"File '{file_path}' contains fewer than 3 names. Please add more names to the file.")
                return False
            
            print(f"✅ Successfully loaded {len(self.names)} names from '{file_path}'")
            return True
            
        except FileNotFoundError:
            print(f"❌ File '{file_path}' not found.")
            
            # Offer to create the file if it's the default names.txt
            if file_path == "names.txt":
                create_file = input("Would you like to create 'names.txt' with some example names? (y/n): ").strip().lower()
                if create_file in ['y', 'yes']:
                    return self._create_sample_names_file()
            
            return False
        except Exception as e:
            print(f"❌ Error reading file '{file_path}': {e}")
            return False
    
    def _create_sample_names_file(self) -> bool:
        """Create a sample names.txt file with example names."""
        sample_names = [
            "Emma", "Olivia", "Sophia", "Isabella", "Ava",
            "Liam", "Noah", "William", "James", "Oliver",
            "Charlotte", "Amelia", "Harper", "Evelyn", "Abigail",
            "Benjamin", "Lucas", "Henry", "Alexander", "Mason"
        ]
        
        try:
            with open("names.txt", "w") as file:
                for name in sample_names:
                    file.write(f"{name}\n")
            
            print("✅ Created 'names.txt' with 20 sample names!")
            print("You can edit this file to add your own names before playing.")
            
            use_samples = input("Would you like to use these sample names for now? (y/n): ").strip().lower()
            if use_samples in ['y', 'yes']:
                for name in sample_names:
                    self.names.append(name)
                    self.scores[name] = 0
                return True
            else:
                print("Please edit 'names.txt' with your preferred names and try again.")
                return False
                
        except Exception as e:
            print(f"❌ Could not create sample file: {e}")
            return False
    
    def save_names_to_file(self) -> None:
        """Save current names to a file for future use."""
        try:
            with open("names.txt", "w") as file:
                for name in self.names:
                    file.write(f"{name}\n")
            print("✅ Names saved to 'names.txt' for future use!")
        except Exception as e:
            print(f"Could not save names: {e}")
    
    def get_next_three_names(self) -> List[str]:
        """Get the next 3 names for ranking."""
        available_names = [name for name in self.names if name not in self.used_names]
        
        if len(available_names) == 0:
            return []
        elif len(available_names) < 3:
            # Return all remaining names
            return available_names.copy()
        else:
            # Randomly select 3 names
            return random.sample(available_names, 3)
    
    def display_names(self, names: List[str]) -> None:
        """Display the current set of names."""
        print("\n" + "=" * 40)
        print(f"Round {self.round_number}")
        print("=" * 40)
        print("Choose from these names:")
        for i, name in enumerate(names, 1):
            print(f"{i}. {name}")
    
    def get_user_rankings(self, names: List[str]) -> Tuple[str, str]:
        """Get user's 1st and 2nd choice from the names."""
        while True:
            try:
                print(f"\nFrom the {len(names)} names above:")
                first_choice = int(input("Enter the number of your FAVORITE name: ")) - 1
                
                if first_choice < 0 or first_choice >= len(names):
                    print(f"Please enter a number between 1 and {len(names)}")
                    continue
                
                if len(names) > 1:
                    second_choice = int(input("Enter the number of your SECOND favorite name: ")) - 1
                    
                    if second_choice < 0 or second_choice >= len(names):
                        print(f"Please enter a number between 1 and {len(names)}")
                        continue
                    
                    if second_choice == first_choice:
                        print("Please choose two different names.")
                        continue
                else:
                    second_choice = -1  # No second choice if only one name
                
                return names[first_choice], names[second_choice] if second_choice != -1 else None
                
            except (ValueError, IndexError):
                print(f"Please enter a valid number between 1 and {len(names)}")
    
    def update_scores(self, first_choice: str, second_choice: str = None) -> None:
        """Update scores based on user choices."""
        self.scores[first_choice] += 3  # 3 points for first place
        if second_choice:
            self.scores[second_choice] += 1  # 1 point for second place
    
    def mark_names_as_used(self, names: List[str]) -> None:
        """Mark names as used so they won't appear again."""
        for name in names:
            self.used_names.add(name)
    
    def play_round(self) -> bool:
        """Play one round of the game. Returns False when game is over."""
        current_names = self.get_next_three_names()
        
        if not current_names:
            return False  # Game over
        
        self.round_number += 1
        self.display_names(current_names)
        
        first_choice, second_choice = self.get_user_rankings(current_names)
        self.update_scores(first_choice, second_choice)
        self.mark_names_as_used(current_names)
        
        print(f"\n✅ You chose '{first_choice}' as #1", end="")
        if second_choice:
            print(f" and '{second_choice}' as #2")
        else:
            print()
        
        return True  # Continue game
    
    def display_final_results(self) -> None:
        """Display the final rankings and scores."""
        print("\n" + "🏆" * 20)
        print("FINAL RESULTS")
        print("🏆" * 20)
        
        # Sort names by score (highest first)
        sorted_names = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
        
        print(f"\nOut of {len(self.names)} names, here are your rankings:")
        print("-" * 50)
        
        for rank, (name, score) in enumerate(sorted_names, 1):
            emoji = "🥇" if rank == 1 else "🥈" if rank == 2 else "🥉" if rank == 3 else "  "
            print(f"{emoji} {rank:2d}. {name:<20} ({score} points)")
        
        # Show top 3 favorites
        top_names = sorted_names[:3]
        print(f"\n🌟 Your top 3 favorite names:")
        for i, (name, score) in enumerate(top_names, 1):
            print(f"   {i}. {name} ({score} points)")
        
        # Show statistics
        total_rounds = self.round_number
        total_possible_points = total_rounds * 4  # 3 + 1 points per round max
        print(f"\n📊 Game Statistics:")
        print(f"   • Total rounds played: {total_rounds}")
        print(f"   • Names evaluated: {len(self.names)}")
        print(f"   • Average score: {sum(self.scores.values()) / len(self.scores):.1f}")
    
    def play_game(self) -> None:
        """Main game loop."""
        # Load names
        self.load_names_from_input()
        
        if len(self.names) < 3:
            print("You need at least 3 names to play. Please restart and add more names.")
            return
        
        print(f"\n🎮 Starting game with {len(self.names)} names!")
        print("Let's begin ranking...")
        
        # Offer to save names
        save = input("\nWould you like to save these names for future games? (y/n): ").strip().lower()
        if save in ['y', 'yes']:
            self.save_names_to_file()
        
        # Shuffle names for random order
        random.shuffle(self.names)
        
        # Play rounds until all names are used
        while self.play_round():
            remaining = len(self.names) - len(self.used_names)
            if remaining > 0:
                input(f"\nPress Enter to continue to next round... ({remaining} names remaining)")
        
        # Show final results
        self.display_final_results()
        
        # Ask about playing again
        play_again = input("\nWould you like to play again with the same names? (y/n): ").strip().lower()
        if play_again in ['y', 'yes']:
            self.reset_game()
            self.play_game()
    
    def reset_game(self) -> None:
        """Reset game state for a new round."""
        self.used_names.clear()
        self.round_number = 0
        for name in self.scores:
            self.scores[name] = 0


def main():
    """Main function to run the baby name game."""
    game = BabyNameGame()
    
    try:
        game.play_game()
    except KeyboardInterrupt:
        print("\n\n👋 Thanks for playing! Your baby name rankings were saved.")
    except Exception as e:
        print(f"\n❌ An error occurred: {e}")
        print("Please try running the game again.")


if __name__ == "__main__":
    main()
