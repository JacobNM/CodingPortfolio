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
        self.total_rounds_completed = 0
        self.is_two_player = False
        self.current_player = 1
        self.player_names = ["Player 1", "Player 2"]
        
    def load_names_from_input(self) -> None:
        """Load baby names from user input."""
        print("🍼 Welcome to the Baby Name Ranking Game! 🍼")
        print("=" * 50)
        print("This game will help you and your partner rank baby names.")
        print("You'll see 2 names at a time and pick your favorite.")
        print("Names get points: 1 for winner, 0 for loser")
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
                if len(self.names) < 2:
                    print("Please enter at least 2 names to play the game.")
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
        
        if len(self.names) < 2:
            print("Please enter at least 2 names. Let's try again.")
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
            
            if len(self.names) < 2:
                print(f"File '{file_path}' contains fewer than 2 names. Please add more names to the file.")
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
    
    def get_next_two_names(self) -> List[str]:
        """Get the next 2 names for ranking."""
        available_names = [name for name in self.names if name not in self.used_names]
        
        if len(available_names) == 0:
            return []
        elif len(available_names) == 1:
            # Return the last remaining name
            return available_names.copy()
        else:
            # Randomly select 2 names
            return random.sample(available_names, 2)
    
    def display_names(self, names: List[str], show_header: bool = True) -> None:
        """Display the current set of names."""
        if show_header:
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
        """Get user's choice from the names."""
        while True:
            try:
                if len(names) == 1:
                    print(f"\nOnly 1 name remaining: {names[0]}")
                    print("This name automatically gets 1 point.")
                    return names[0], None
                elif len(names) == 2:
                    print(f"\nWhich name do you prefer?")
                    choice = int(input("Enter the number of your FAVORITE name: ")) - 1
                    
                    if choice < 0 or choice >= len(names):
                        print(f"Please enter a number between 1 and {len(names)}")
                        continue
                    
                    return names[choice], None
                else:
                    # Handle cases with more than 2 names (like tiebreakers)
                    print(f"\nFrom the {len(names)} names above:")
                    choice = int(input("Enter the number of your FAVORITE name: ")) - 1
                    
                    if choice < 0 or choice >= len(names):
                        print(f"Please enter a number between 1 and {len(names)}")
                        continue
                    
                    return names[choice], None
                
            except (ValueError, IndexError):
                print(f"Please enter a valid number between 1 and {len(names)}")
    
    def update_scores(self, first_choice: str, second_choice: str = None) -> None:
        """Update scores based on user choices."""
        if self.is_two_player:
            current_player_name = self.player_names[self.current_player - 1]
            self.player_scores[current_player_name][first_choice] += 1  # 1 point for winner
        else:
            self.scores[first_choice] += 1  # 1 point for winner
    
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
        print(f"\n✅ {player_name} chose '{first_choice}' as the winner")
        
        return True  # Continue game
    
    def display_final_results(self) -> None:
        """Display the final rankings and scores."""
        print("\n" + "🏆" * 20)
        if self.is_two_player:
            print("FINAL RESULTS - BOTH PLAYERS")
        else:
            print("FINAL RESULTS")
        print("🏆" * 20)
        
        # Check for tiebreakers before showing results
        if self.is_two_player:
            tiebreaker_needed = self._check_two_player_tiebreaker()
        else:
            tiebreaker_needed = self._check_single_player_tiebreaker()
        
        if tiebreaker_needed:
            return  # Results will be shown after tiebreaker
        
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
    
    def _check_single_player_tiebreaker(self) -> bool:
        """Check if tiebreaker is needed for single player and handle it."""
        sorted_names = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
        
        if len(sorted_names) < 2:
            return False
        
        # Find all names tied for highest score
        highest_score = sorted_names[0][1]
        tied_names = [name for name, score in sorted_names if score == highest_score]
        
        if len(tied_names) > 1 and highest_score > 0:
            print(f"\n🤝 TIE DETECTED! {len(tied_names)} names are tied for the highest score ({highest_score} points):")
            for name in tied_names:
                print(f"   • {name}")
            
            proceed = input(f"\nWould you like a tiebreaker round to choose your true favorite? (y/n): ").strip().lower()
            if proceed in ['y', 'yes']:
                winner, runner_up = self._run_tiebreaker(tied_names)
                self._update_tiebreaker_scores(winner, runner_up, highest_score)
                
                print(f"\n🎉 Tiebreaker complete! Final results:")
                self._display_single_player_results()
                
                # Offer export after tiebreaker
                export = input(f"\n💾 Export results to spreadsheet (CSV)? (y/n): ").strip().lower()
                if export in ['y', 'yes']:
                    final_sorted = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
                    self.export_to_csv(final_sorted)
                
                return True
        
        return False
    
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
        print(f"\n📊 Game Statistics:")
        print(f"   • Total rounds completed: {self.total_rounds_completed}")
        print(f"   • Names evaluated: {len(self.names)}")
        print(f"   • Total pairings per player: {self.total_rounds_completed * len(self.names) // 2}")
        print(f"   • {self.player_names[0]} average score: {sum(self.player_scores[self.player_names[0]].values()) / len(self.names):.1f}")
        print(f"   • {self.player_names[1]} average score: {sum(self.player_scores[self.player_names[1]].values()) / len(self.names):.1f}")
    
    def _check_two_player_tiebreaker(self) -> bool:
        """Check if tiebreaker is needed for two player mode and handle it."""
        tiebreaker_ran = False
        players_with_ties = []
        
        # First, check which players have ties
        for i, player_name in enumerate(self.player_names):
            player_scores = self.player_scores[player_name]
            sorted_player_scores = sorted(player_scores.items(), key=lambda x: x[1], reverse=True)
            
            if len(sorted_player_scores) >= 2:
                highest_score = sorted_player_scores[0][1]
                tied_names = [name for name, score in sorted_player_scores if score == highest_score]
                
                if len(tied_names) > 1 and highest_score > 0:
                    players_with_ties.append((i, player_name, tied_names, highest_score))
        
        # Now handle tiebreakers for each player
        for idx, (player_index, player_name, tied_names, highest_score) in enumerate(players_with_ties):
            print(f"\n🤝 {player_name.upper()} TIE DETECTED!")
            print(f"{len(tied_names)} names are tied for {player_name}'s highest score ({highest_score} points):")
            for name in tied_names:
                print(f"   • {name}")
            
            proceed = input(f"\n{player_name}, would you like a tiebreaker round to choose your true favorite? (y/n): ").strip().lower()
            if proceed in ['y', 'yes']:
                print(f"\n👤 {player_name}'s Tiebreaker Round")
                winner, runner_up = self._run_individual_tiebreaker(tied_names, player_name)
                self._update_individual_tiebreaker_scores(winner, runner_up, player_name, highest_score)
                tiebreaker_ran = True
                print(f"✅ {player_name}'s tiebreaker complete!")
                
                # Clear screen after first player's tiebreaker if there's a second player with ties
                if idx == 0 and len(players_with_ties) > 1:
                    input("\nPress Enter to continue to next player's tiebreaker...")
                    os.system('cls' if os.name == 'nt' else 'clear')
        
        if tiebreaker_ran:
            print(f"\n🎉 All tiebreakers complete! Final results:")
            self._display_two_player_results()
            
            # Offer export after tiebreaker
            export = input(f"\n💾 Export results to spreadsheet (CSV)? (y/n): ").strip().lower()
            if export in ['y', 'yes']:
                self.export_two_player_csv()
            
            return True
        
        return False
    
    def _run_tiebreaker(self, tied_names: List[str]) -> Tuple[str, str]:
        """Run a tiebreaker round for single player."""
        print(f"\n🥊 TIEBREAKER ROUND")
        print("=" * 20)
        print(f"Choose from these {len(tied_names)} tied names:")
        
        for i, name in enumerate(tied_names, 1):
            print(f"{i}. {name}")
        
        first_choice, second_choice = self.get_user_rankings(tied_names)
        return first_choice, second_choice
    
    def _run_joint_tiebreaker(self, tied_names: List[str]) -> Tuple[str, str]:
        """Run an individual tiebreaker round for a specific player."""
        # This method is now replaced by _run_individual_tiebreaker
        # Keeping for backwards compatibility but redirecting
        return self._run_individual_tiebreaker(tied_names, "Player")
    
    def _run_individual_tiebreaker(self, tied_names: List[str], player_name: str) -> Tuple[str, str]:
        """Run a tiebreaker round for an individual player."""
        print(f"\n🥊 {player_name.upper()}'S TIEBREAKER ROUND")
        print("=" * 40)
        print(f"{player_name}, choose from these {len(tied_names)} tied names:")
        
        for i, name in enumerate(tied_names, 1):
            print(f"{i}. {name}")
        
        first_choice, second_choice = self.get_user_rankings(tied_names)
        return first_choice, second_choice
    
    def _update_tiebreaker_scores(self, winner: str, runner_up: str, original_high_score: int) -> None:
        """Update scores after single player tiebreaker."""
        # Give winner a higher score than the original tie
        self.scores[winner] = original_high_score + 1
    
    def _update_combined_tiebreaker_scores(self, winner: str, runner_up: str, tied_names: List[str]) -> None:
        """Update scores after two player tiebreaker by adding bonus points."""
        # This method is now replaced by _update_individual_tiebreaker_scores
        # Keeping for backwards compatibility
        pass
    
    def _update_individual_tiebreaker_scores(self, winner: str, runner_up: str, player_name: str, original_high_score: int) -> None:
        """Update scores after individual player tiebreaker."""
        # Give winner a higher score than the original tie for this specific player
        self.player_scores[player_name][winner] = original_high_score + 1
    
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
        
        if len(self.names) < 2:
            print("You need at least 2 names to play. Please restart and add more names.")
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
        """Play the game in single player mode with multiple rounds."""
        while True:
            self.total_rounds_completed += 1
            print(f"\n🎮 Starting Round {self.total_rounds_completed}")
            
            # Get pairings for this round (prioritizes tied names after first round)
            round_pairings = self._get_round_pairings()
            
            # Play through all pairings
            for i, pairing in enumerate(round_pairings, 1):
                if len(pairing) == 2:
                    print(f"\n{'=' * 40}")
                    print(f"Pairing {i}")
                    print(f"{'=' * 40}")
                    self.display_names(pairing, show_header=False)  # Don't show duplicate header
                    
                    first_choice, second_choice = self.get_user_rankings(pairing)
                    self.update_scores(first_choice, second_choice)
                    
                    print(f"\n✅ You chose '{first_choice}' as the winner")
                    
                    # Pause between pairings if there are more
                    if i < len(round_pairings):
                        input(f"\nPress Enter to continue... ({len(round_pairings) - i} pairings remaining)")
                elif len(pairing) == 1:
                    # Handle odd name by giving it a small bonus
                    print(f"\n📝 '{pairing[0]}' gets a small bonus for making it to the final pairing!")
                    self.scores[pairing[0]] = self.scores.get(pairing[0], 0) + 0.5
            
            # Show current standings
            print(f"\n📈 Round {self.total_rounds_completed} Complete!")
            sorted_names = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
            print("Current standings:")
            for i, (name, score) in enumerate(sorted_names[:5], 1):
                print(f"  {i}. {name} ({score} points)")
            
            # Show tied names
            tied_names = self._get_tied_names_for_highest_score()
            if len(tied_names) > 1:
                print(f"\n🔄 Names tied for highest score ({sorted_names[0][1]} points): {', '.join(tied_names)}")
                print("Next round will focus on these tied names!")
                continue_round = input("Play another round to break ties? (y/n): ").strip().lower()
            else:
                continue_round = input(f"\n🔄 Play another round to refine rankings? (y/n): ").strip().lower()
            
            if continue_round not in ['y', 'yes']:
                break
    
    def _play_two_player_game(self) -> None:
        """Play the game in two player mode with multiple rounds."""
        print(f"\n🎮 {self.player_names[0]} will play first, then {self.player_names[1]} will play with the same pairings!")
        
        while True:
            self.total_rounds_completed += 1
            print(f"\n🎯 Round {self.total_rounds_completed} - Both Players")
            
            # Shuffle names for this round's pairings
            random.shuffle(self.names)
            round_pairings = self._get_round_pairings()
            
            # Player 1's turn
            self._play_player_round(1, round_pairings)
            
            # Clear screen and switch to Player 2
            input(f"\n🔄 {self.player_names[0]}'s turn complete. Press Enter for {self.player_names[1]}'s turn...")
            os.system('cls' if os.name == 'nt' else 'clear')
            
            # Player 2's turn with same pairings
            self._play_player_round(2, round_pairings)
            
            # Show current standings
            print(f"\n📈 Round {self.total_rounds_completed} Complete!")
            self._show_round_standings()
            
            # Ask for another round
            if self._has_meaningful_ties():
                continue_round = input("Play another round to break ties? (y/n): ").strip().lower()
            else:
                continue_round = input(f"\n🔄 Play another round to refine rankings? (y/n): ").strip().lower()
            
            if continue_round not in ['y', 'yes']:
                break
    
    def _get_tied_names_for_highest_score(self) -> List[str]:
        """Get names tied for the highest score."""
        if self.is_two_player:
            # For two-player, get union of names tied for highest in each player's scores
            all_tied_names = set()
            for player_name in self.player_names:
                player_scores = self.player_scores[player_name]
                if not player_scores:
                    continue
                sorted_scores = sorted(player_scores.items(), key=lambda x: x[1], reverse=True)
                if sorted_scores:
                    highest_score = sorted_scores[0][1]
                    tied_names = [name for name, score in sorted_scores if score == highest_score]
                    all_tied_names.update(tied_names)
            return list(all_tied_names)
        else:
            # Single player mode
            if not self.scores:
                return []
            sorted_names = sorted(self.scores.items(), key=lambda x: x[1], reverse=True)
            if sorted_names:
                highest_score = sorted_names[0][1]
                return [name for name, score in sorted_names if score == highest_score]
            return []
    
    def _get_round_pairings(self) -> List[List[str]]:
        """Get all pairings for a complete round, prioritizing tied names."""
        # After first round is completed, prioritize names tied for highest score
        if self.total_rounds_completed > 1:
            tied_names = self._get_tied_names_for_highest_score()
            if len(tied_names) > 1:
                # If there are exactly 2 tied names, only use those 2
                if len(tied_names) == 2:
                    available_names = tied_names.copy()
                    random.shuffle(available_names)
                # If there are 3+ tied names, focus on them but include some others for comparison
                else:
                    priority_names = tied_names.copy()
                    other_names = [name for name in self.names if name not in tied_names]
                    random.shuffle(priority_names)
                    random.shuffle(other_names)
                    
                    # Use mostly tied names, with some others mixed in
                    available_names = priority_names + other_names[:len(tied_names)//2]
                    random.shuffle(available_names)
            else:
                available_names = self.names.copy()
                random.shuffle(available_names)
        else:
            available_names = self.names.copy()
            random.shuffle(available_names)
        
        pairings = []
        while len(available_names) >= 2:
            pair = available_names[:2]
            pairings.append(pair)
            available_names = available_names[2:]
        
        # Handle odd name only if we're not in a focused 2-name comparison
        if available_names and len(self._get_tied_names_for_highest_score()) != 2:
            pairings.append([available_names[0]])
        
        return pairings
    
    def _has_meaningful_ties(self) -> bool:
        """Check if there are meaningful ties that warrant another round."""
        tied_names = self._get_tied_names_for_highest_score()
        return len(tied_names) > 1
    
    def _show_round_standings(self) -> None:
        """Show current standings after a round in two-player mode."""
        for player_name in self.player_names:
            player_scores = self.player_scores[player_name]
            sorted_scores = sorted(player_scores.items(), key=lambda x: x[1], reverse=True)
            print(f"\n{player_name}'s current standings:")
            for i, (name, score) in enumerate(sorted_scores[:5], 1):
                print(f"  {i}. {name} ({score} points)")
        
        # Show names tied for highest scores
        tied_names = self._get_tied_names_for_highest_score()
        if len(tied_names) > 1:
            print(f"\n🔄 Names with ties for highest scores: {', '.join(tied_names)}")
            print("Next round will focus on these names!")
    
    def _play_player_round(self, player_num: int, pairings: List[List[str]]) -> None:
        """Play one player's turn through all pairings."""
        self.current_player = player_num
        player_name = self.player_names[player_num - 1]
        
        print(f"\n👤 {player_name}'s Turn - Round {self.total_rounds_completed}")
        input("Press Enter when ready...")
        
        for i, names in enumerate(pairings, 1):
            print(f"\n--- Pairing {i} of {len(pairings)} ---")
            if len(names) == 1:
                print(f"Only 1 name remaining: {names[0]}")
                print("This name automatically gets 1 point.")
                first_choice, second_choice = names[0], None
            else:
                self.display_names(names)
                first_choice, second_choice = self.get_user_rankings(names)
            
            self.update_scores(first_choice, second_choice)
            
            player_name = self.player_names[self.current_player - 1]
            print(f"\n✅ {player_name} chose '{first_choice}' as the winner")
            
            if i < len(pairings):
                input(f"\nPress Enter to continue... ({len(pairings) - i} pairings remaining)")
    
    def _show_round_standings(self) -> None:
        """Show current standings after a round."""
        print("\nCurrent standings:")
        
        for i, player_name in enumerate(self.player_names):
            sorted_scores = sorted(self.player_scores[player_name].items(), key=lambda x: x[1], reverse=True)
            print(f"\n{player_name}:")
            for j, (name, score) in enumerate(sorted_scores[:5], 1):
                print(f"  {j}. {name} ({score} points)")
    
    def _has_meaningful_ties(self) -> bool:
        """Check if there are ties that would benefit from another round."""
        for player_name in self.player_names:
            sorted_scores = sorted(self.player_scores[player_name].items(), key=lambda x: x[1], reverse=True)
            if len(sorted_scores) >= 2:
                highest_score = sorted_scores[0][1]
                tied_count = len([score for _, score in sorted_scores if score == highest_score])
                if tied_count > 1:
                    return True
        return False
    
    def reset_game(self) -> None:
        """Reset game state for a new round."""
        self.used_names.clear()
        self.round_number = 0
        self.total_rounds_completed = 0
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
