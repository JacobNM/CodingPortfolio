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
import csv
import os
from datetime import datetime
from typing import List, Dict, Tuple


class BabyNameGame:
    def __init__(self):
        self.names = []
        self.scores = {}  # For single player mode
        self.player_scores = {}  # For two player mode: {player_name: {name: score}}
        self.used_names = set()
        self.round_number = 0
        self.is_two_player = False
        self.current_player = 1
        self.player_names = ["Player 1", "Player 2"]
        
    def load_names_from_input(self) -> None:
        """Load baby names from user input."""
        print("🍼 Welcome to the Baby Name Ranking Game! 🍼")
        print("=" * 50)
        print("This game will help you and your partner rank baby names.")
        print("You'll see 3 names at a time and pick your 1st and 2nd favorites.")
        print("Names get points: 3 for 1st place, 1 for 2nd place, 0 for 3rd place")
        print()
        
        # Ask for game mode
        while True:
            print("Game Mode:")
            print("1. Single Player (just you)")
            print("2. Two Player (you and your partner)")
            mode = input("Choose mode (1-2): ").strip()
            
            if mode == "1":
                self.is_two_player = False
                break
            elif mode == "2":
                self.is_two_player = True
                self._get_player_names()
                break
            else:
                print("Please enter 1 or 2.\n")
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
                    if self.is_two_player:
                        for player in self.player_names:
                            if player not in self.player_scores:
                                self.player_scores[player] = {}
                            self.player_scores[player][name] = 0
                    if self.is_two_player:
                        for player in self.player_names:
                            if player not in self.player_scores:
                                self.player_scores[player] = {}
                            self.player_scores[player][name] = 0
        
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
    
    def _get_player_names(self) -> None:
        """Get custom names for both players."""
        print("\nEnter names for both players (or press Enter for defaults):")
        player1 = input("Player 1 name: ").strip()
        if player1:
            self.player_names[0] = player1
        
        player2 = input("Player 2 name: ").strip()
        if player2:
            self.player_names[1] = player2
        
        print(f"Great! {self.player_names[0]} will play first, then {self.player_names[1]}.")
    
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
        """Get the next 3 names for ranking (or 4 if exactly 4 remain)."""
        available_names = [name for name in self.names if name not in self.used_names]
        
        if len(available_names) == 0:
            return []
        elif len(available_names) == 4:
            # Include all 4 names in this round to avoid a final round with just 1 name
            return available_names.copy()
        elif len(available_names) < 3:
            # Return all remaining names (1 or 2)
            return available_names.copy()
        else:
            # Randomly select 3 names
            return random.sample(available_names, 3)
    
    def display_names(self, names: List[str]) -> None:
        """Display the current set of names."""
        print("\n" + "=" * 40)
        if self.is_two_player:
            current_player_name = self.player_names[self.current_player - 1]
            print(f"Round {self.round_number} - {current_player_name}'s Turn")
        else:
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
                    print("Enter the number of your SECOND favorite name:")
                    if len(names) == 4:
                        print("(Note: This round has 4 names to avoid a single-name final round)")
                    second_choice = int(input("Second favorite: ")) - 1
                    
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
        if self.is_two_player:
            current_player_name = self.player_names[self.current_player - 1]
            self.player_scores[current_player_name][first_choice] += 3
            if second_choice:
                self.player_scores[current_player_name][second_choice] += 1
        else:
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
        
        player_name = self.player_names[self.current_player - 1] if self.is_two_player else "You"
        print(f"\n✅ {player_name} chose '{first_choice}' as #1", end="")
        if second_choice:
            print(f" and '{second_choice}' as #2")
        else:
            print()
        
        return True  # Continue game
    
    def display_final_results(self) -> None:
        """Display the final rankings and scores."""
        print("\n" + "🏆" * 20)
        if self.is_two_player:
            print("FINAL RESULTS - BOTH PLAYERS")
        else:
            print("FINAL RESULTS")
        print("🏆" * 20)
        
        if self.is_two_player:
            self._display_two_player_results()
        else:
            self._display_single_player_results()
        
        # Offer to export to spreadsheet
        export = input(f"\n💾 Export results to spreadsheet (CSV)? (y/n): ").strip().lower()
        if export in ['y', 'yes']:
            if self.is_two_player:
                self.export_two_player_csv()
            else:
                sorted_names = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
                self.export_to_csv(sorted_names)
    
    def _display_single_player_results(self) -> None:
        """Display results for single player mode."""
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
        print(f"\n📊 Game Statistics:")
        print(f"   • Total rounds played: {total_rounds}")
        print(f"   • Names evaluated: {len(self.names)}")
        print(f"   • Average score: {sum(self.scores.values()) / len(self.scores):.1f}")
    
    def _display_two_player_results(self) -> None:
        """Display results for two player mode."""
        print(f"\n{self.player_names[0]} vs {self.player_names[1]} - Name Rankings Comparison")
        print("=" * 70)
        
        # Get sorted results for both players
        player1_sorted = sorted(self.player_scores[self.player_names[0]].items(), key=lambda x: x[1], reverse=True)
        player2_sorted = sorted(self.player_scores[self.player_names[1]].items(), key=lambda x: x[1], reverse=True)
        
        # Display side-by-side comparison
        print(f"{'RANK':<4} {self.player_names[0]:<25} {self.player_names[1]:<25}")
        print("-" * 70)
        
        max_len = max(len(player1_sorted), len(player2_sorted))
        for i in range(max_len):
            rank = i + 1
            p1_info = f"{player1_sorted[i][0]} ({player1_sorted[i][1]})" if i < len(player1_sorted) else ""
            p2_info = f"{player2_sorted[i][0]} ({player2_sorted[i][1]})" if i < len(player2_sorted) else ""
            
            emoji = "🥇" if rank == 1 else "🥈" if rank == 2 else "🥉" if rank == 3 else ""
            print(f"{emoji}{rank:<3} {p1_info:<25} {p2_info:<25}")
        
        # Show agreements and disagreements
        self._show_player_comparison(player1_sorted, player2_sorted)
    
    def _show_player_comparison(self, player1_sorted, player2_sorted) -> None:
        """Show areas of agreement and disagreement between players."""
        print(f"\n🤝 Agreement Analysis:")
        
        # Find top 3 matches
        p1_top3 = [name for name, _ in player1_sorted[:3]]
        p2_top3 = [name for name, _ in player2_sorted[:3]]
        common_top3 = set(p1_top3).intersection(set(p2_top3))
        
        if common_top3:
            print(f"   ✅ You both love: {', '.join(common_top3)}")
        
        # Find biggest disagreements (one player's top 3 vs other's bottom 3)
        p1_bottom3 = [name for name, _ in player1_sorted[-3:]]
        p2_bottom3 = [name for name, _ in player2_sorted[-3:]]
        
        p1_high_p2_low = set(p1_top3).intersection(set(p2_bottom3))
        p2_high_p1_low = set(p2_top3).intersection(set(p1_bottom3))
        
        if p1_high_p2_low:
            print(f"   ⚠️  {self.player_names[0]} loves but {self.player_names[1]} doesn't: {', '.join(p1_high_p2_low)}")
        if p2_high_p1_low:
            print(f"   ⚠️  {self.player_names[1]} loves but {self.player_names[0]} doesn't: {', '.join(p2_high_p1_low)}")
        
        # Statistics
        total_rounds = self.round_number // 2  # Each name evaluated by both players
        print(f"\n📊 Game Statistics:")
        print(f"   • Total rounds per player: {total_rounds}")
        print(f"   • Names evaluated: {len(self.names)}")
        print(f"   • {self.player_names[0]} average score: {sum(self.player_scores[self.player_names[0]].values()) / len(self.names):.1f}")
        print(f"   • {self.player_names[1]} average score: {sum(self.player_scores[self.player_names[1]].values()) / len(self.names):.1f}")
    
    def export_to_csv(self, sorted_names: List[Tuple[str, int]]) -> None:
        """Export game results to a CSV file."""
        try:
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"baby_name_rankings_{timestamp}.csv"
            
            # Create path to user's Downloads folder
            downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")
            full_path = os.path.join(downloads_path, filename)
            
            with open(full_path, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header information
                writer.writerow(['Baby Name Rankings Game Results'])
                writer.writerow(['Generated:', datetime.now().strftime("%Y-%m-%d %H:%M:%S")])
                writer.writerow(['Total Names:', len(self.names)])
                writer.writerow(['Total Rounds:', self.round_number])
                writer.writerow([])  # Empty row
                
                # Write column headers
                writer.writerow(['Rank', 'Name', 'Score', 'Percentage'])
                
                # Calculate max possible score for percentage
                max_possible = max([score for _, score in sorted_names]) if sorted_names else 1
                
                # Write rankings data
                for rank, (name, score) in enumerate(sorted_names, 1):
                    percentage = (score / max_possible * 100) if max_possible > 0 else 0
                    writer.writerow([rank, name, score, f"{percentage:.1f}%"])
                
                # Add summary section
                writer.writerow([])  # Empty row
                writer.writerow(['Summary Statistics'])
                writer.writerow(['Top Choice:', sorted_names[0][0] if sorted_names else 'N/A'])
                writer.writerow(['Highest Score:', sorted_names[0][1] if sorted_names else 0])
                writer.writerow(['Average Score:', f"{sum(self.scores.values()) / len(self.scores):.1f}"])
                writer.writerow(['Score Range:', f"{sorted_names[-1][1]} - {sorted_names[0][1]}" if len(sorted_names) > 1 else "N/A"])
            
            print(f"✅ Results exported to Downloads: {filename}")
            print(f"📁 Full path: {full_path}")
            print(f"📊 Open this file in Excel, Google Sheets, or any spreadsheet app!")
            
        except Exception as e:
            print(f"❌ Export failed: {e}")
            print("Results are still displayed above for manual entry.")
    
    def export_two_player_csv(self) -> None:
        """Export two-player game results to a CSV file."""
        try:
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"baby_name_rankings_2player_{timestamp}.csv"
            
            # Create path to user's Downloads folder
            downloads_path = os.path.join(os.path.expanduser("~"), "Downloads")
            full_path = os.path.join(downloads_path, filename)
            
            # Get sorted results for both players
            player1_sorted = sorted(self.player_scores[self.player_names[0]].items(), key=lambda x: x[1], reverse=True)
            player2_sorted = sorted(self.player_scores[self.player_names[1]].items(), key=lambda x: x[1], reverse=True)
            
            with open(full_path, 'w', newline='', encoding='utf-8') as csvfile:
                writer = csv.writer(csvfile)
                
                # Write header information
                writer.writerow(['Baby Name Rankings Game - Two Player Results'])
                writer.writerow(['Generated:', datetime.now().strftime("%Y-%m-%d %H:%M:%S")])
                writer.writerow(['Players:', f"{self.player_names[0]} vs {self.player_names[1]}"])
                writer.writerow(['Total Names:', len(self.names)])
                writer.writerow(['Rounds per Player:', self.round_number // 2])
                writer.writerow([])  # Empty row
                
                # Write comparison table
                writer.writerow(['RANKINGS COMPARISON'])
                writer.writerow(['Rank', f'{self.player_names[0]} - Name', f'{self.player_names[0]} - Score', 
                               f'{self.player_names[1]} - Name', f'{self.player_names[1]} - Score'])
                
                max_len = max(len(player1_sorted), len(player2_sorted))
                for i in range(max_len):
                    rank = i + 1
                    p1_name = player1_sorted[i][0] if i < len(player1_sorted) else ""
                    p1_score = player1_sorted[i][1] if i < len(player1_sorted) else ""
                    p2_name = player2_sorted[i][0] if i < len(player2_sorted) else ""
                    p2_score = player2_sorted[i][1] if i < len(player2_sorted) else ""
                    
                    writer.writerow([rank, p1_name, p1_score, p2_name, p2_score])
                
                # Add agreement analysis
                writer.writerow([])  # Empty row
                writer.writerow(['AGREEMENT ANALYSIS'])
                
                # Find agreements
                p1_top3 = [name for name, _ in player1_sorted[:3]]
                p2_top3 = [name for name, _ in player2_sorted[:3]]
                common_top3 = set(p1_top3).intersection(set(p2_top3))
                
                writer.writerow(['Both Players Top 3:', ', '.join(common_top3) if common_top3 else 'No common favorites'])
                
                # Find disagreements
                p1_bottom3 = [name for name, _ in player1_sorted[-3:]]
                p2_bottom3 = [name for name, _ in player2_sorted[-3:]]
                
                p1_high_p2_low = set(p1_top3).intersection(set(p2_bottom3))
                p2_high_p1_low = set(p2_top3).intersection(set(p1_bottom3))
                
                if p1_high_p2_low:
                    writer.writerow([f'{self.player_names[0]} loves, {self.player_names[1]} doesn\'t:', ', '.join(p1_high_p2_low)])
                if p2_high_p1_low:
                    writer.writerow([f'{self.player_names[1]} loves, {self.player_names[0]} doesn\'t:', ', '.join(p2_high_p1_low)])
                
                # Add detailed scores for all names
                writer.writerow([])  # Empty row
                writer.writerow(['DETAILED SCORES - ALL NAMES'])
                writer.writerow(['Name', f'{self.player_names[0]} Score', f'{self.player_names[1]} Score', 'Combined Score', 'Agreement Level'])
                
                for name in self.names:
                    p1_score = self.player_scores[self.player_names[0]][name]
                    p2_score = self.player_scores[self.player_names[1]][name]
                    combined = p1_score + p2_score
                    
                    # Calculate agreement level
                    if p1_score == p2_score:
                        agreement = "Perfect Match"
                    elif abs(p1_score - p2_score) <= 1:
                        agreement = "Close"
                    elif abs(p1_score - p2_score) <= 2:
                        agreement = "Different"
                    else:
                        agreement = "Opposite"
                    
                    writer.writerow([name, p1_score, p2_score, combined, agreement])
            
            print(f"✅ Two-player results exported to Downloads: {filename}")
            print(f"📁 Full path: {full_path}")
            print(f"📊 Open this file in Excel, Google Sheets, or any spreadsheet app!")
            
        except Exception as e:
            print(f"❌ Export failed: {e}")
            print("Results are still displayed above for manual entry.")
    
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
        
        # Initialize player scores for two-player mode
        if self.is_two_player:
            for player in self.player_names:
                self.player_scores[player] = {}
                for name in self.names:
                    self.player_scores[player][name] = 0
        
        # Play rounds until all names are used
        if self.is_two_player:
            self._play_two_player_game()
        else:
            self._play_single_player_game()
        
        # Show final results
        self.display_final_results()
        
        # Ask about playing again
        play_again = input("\nWould you like to play again with the same names? (y/n): ").strip().lower()
        if play_again in ['y', 'yes']:
            self.reset_game()
            self.play_game()
    
    def _play_single_player_game(self) -> None:
        """Play the game in single player mode."""
        while self.play_round():
            remaining = len(self.names) - len(self.used_names)
            if remaining > 0:
                input(f"\nPress Enter to continue to next round... ({remaining} names remaining)")
    
    def _play_two_player_game(self) -> None:
        """Play the game in two player mode."""
        print(f"\n🎮 {self.player_names[0]} will play first, then {self.player_names[1]} will play with the same names!")
        
        # Player 1's turn - play through all names
        self.current_player = 1
        self.used_names.clear()
        self.round_number = 0
        
        print(f"\n👤 {self.player_names[0]}'s Turn - Let's begin!")
        input("Press Enter when ready...")
        
        while self.play_round():
            remaining = len(self.names) - len(self.used_names)
            if remaining > 0:
                input(f"\nPress Enter to continue to next round... ({remaining} names remaining)")
        
        # Reset for Player 2
        self.used_names.clear()
        self.round_number = 0
        self.current_player = 2
        
        print(f"\n\n🔄 Time for {self.player_names[1]}'s turn!")
        print(f"👤 {self.player_names[1]} will now rank the same names.")
        input("Press Enter when ready...")
        
        # Clear screen so second player doesn't see first player's results
        os.system('cls' if os.name == 'nt' else 'clear')
        
        # Reshuffle for different order
        random.shuffle(self.names)
        
        while self.play_round():
            remaining = len(self.names) - len(self.used_names)
            if remaining > 0:
                input(f"\nPress Enter to continue to next round... ({remaining} names remaining)")
    
    def reset_game(self) -> None:
        """Reset game state for a new round."""
        self.used_names.clear()
        self.round_number = 0
        self.current_player = 1
        
        if self.is_two_player:
            for player in self.player_names:
                for name in self.scores:
                    self.player_scores[player][name] = 0
        else:
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
