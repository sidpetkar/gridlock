# Gridlock - Game Guide

## What is Gridlock?

Gridlock is a strategic word-building game where you compete against an AI opponent to create intersecting words on an expanding grid. Think of it as a dynamic crossword puzzle where you and your opponent take turns adding words, with each new word having to connect to the existing grid. The goal is to score more points than your opponent by placing longer words and creating strategic intersections.

## Game Rules

### Basic Rules

1. **Grid Building**: The game starts with an empty grid that grows as players add words
2. **Word Length**: All words must be at least 3 letters long
3. **Valid Words**: Only real English words are accepted (no abbreviations, acronyms, or proper nouns)
4. **Intersections Required**: After the initial setup phase, every word must share at least one letter with an existing word on the grid
5. **No Overwrites**: You cannot place a word that overwrites or conflicts with existing letters
6. **No Duplicates**: Each word can only be used once per game
7. **No Trivial Extensions**: You cannot simply add letters to make an existing word longer (e.g., if "CAT" exists, you cannot place "CATS" in the same position)

### Game Phases

**Phase 1: Seed A (First Word)**
- Player A (you) places the first word horizontally anywhere on the grid
- This word establishes the starting point for the entire game

**Phase 2: Seed B (Second Word)**
- Player B (bot) places a vertical word that must intersect with your first word
- This creates the initial crossword structure

**Phase 3: Playing (Main Game)**
- Players alternate turns placing words
- Every word must intersect with at least one existing word
- The grid expands but stays locked within the boundaries set after the seed phase
- Game continues until no more valid moves are possible

**Phase 4: Finished (Game Over)**
- Game ends when both players pass consecutively or the board is full
- Final scores are calculated
- Winner is announced

## How to Play

### Starting a New Game

1. Click on the first cell or simply start typing your first word
2. Type a horizontal word (3+ letters)
3. Press **Enter** or click **Submit**
4. The bot will automatically place its intersecting vertical word

### Making Your Move

**Keyboard Navigation (Recommended)**
1. Use **arrow keys** (↑ ↓ ← →) to navigate between cells
2. Click a cell or navigate to it, then start typing
3. When you type the first letter, direction arrows appear
4. Press **Right Arrow** for horizontal or **Down Arrow** for vertical
5. Continue typing your word - the cursor advances automatically
6. Press **Enter** to submit

**Mouse Navigation**
1. Click on an empty cell where you want to start your word
2. Click one of the floating arrow buttons (→ for horizontal, ↓ for vertical)
3. Type your word in the input field
4. Click **Submit**

### Controls

- **Submit**: Place your word on the grid (also: press Enter)
- **Pass**: Skip your turn (use when you have no valid moves)
- **Ghost Hint**: Shows 1-2 faded letters of a valid word you can form - keeps cycling through options each time you click
- **AI Hint**: Get a word suggestion from AI (requires API key)
- **Restart**: Start a fresh game

### Scoring

Points are awarded based on:
- **Word Length**: Longer words score more points
- **Intersections**: Each shared letter multiplies your score
- **Cell Ownership**: 
  - You earn full points for cells you place
  - Shared cells (intersections) split points between both players

The score updates in real-time after each word is placed.

## How to Win

### Winning Strategy

1. **Play Longer Words**: A 7-letter word scores more than two 3-letter words
2. **Create Multiple Intersections**: Words that cross several existing words earn bonus points
3. **Think Ahead**: Consider what opportunities your word creates for your opponent
4. **Use Common Letters**: Words with common letters (E, A, R, S, T) give you more intersection options
5. **Block Your Opponent**: Place words strategically to limit your opponent's options
6. **Save Strong Moves**: Don't use your best words too early when the grid is small

### Victory Conditions

- **Score Victory**: Have more points than your opponent when the game ends
- **Tactical Victory**: Force your opponent into a position where they have no valid moves

### Tips for Beginners

- **Start with medium-length words** (4-6 letters) - they balance scoring and flexibility
- **Use the Ghost Hint** when stuck - it shows you partial letters to help you discover words
- **Don't rush** - take time to explore the grid for the best placement
- **Learn from the bot** - watch where the AI places words and how it creates intersections
- **Master keyboard navigation** - it's much faster than clicking once you get used to it

## Special Features

### Ghost Hints
- Shows 1-2 faded letters of a valid word at your current position
- Click multiple times to cycle through different word suggestions
- The hint letters appear in low opacity directly on the grid
- Helps you discover words you might not have thought of

### Visual Feedback
- **Black border**: Shows your current cell position
- **Colored cells**: Blue for your words, green for bot's words, blended for shared letters
- **Faded letters**: Ghost hint letters guiding you to valid words
- **Blink animation**: Highlights where the bot just played

### Keyboard Shortcuts
- **Arrow keys**: Navigate the grid
- **Right/Down arrows**: Choose word direction (when arrows are visible)
- **Enter**: Submit your word
- **Escape** or click outside the grid: Deselect current cell

## Game Modes

**Current Mode: vs Bot**
- Play against an AI opponent
- Bot uses common, everyday words (beginner-friendly)
- Bot makes strategic moves with random variation

**Coming Soon: 2P Local**
- Play against a friend on the same device
- Take turns entering words

## FAQ

**Q: Why was my word rejected?**
- Make sure it's at least 3 letters long
- Check that it intersects with at least one existing word (after seed phase)
- Verify it's a real dictionary word (not an abbreviation or acronym)
- Ensure it doesn't conflict with existing letters on the grid

**Q: Can I change direction after typing?**
- Yes! Clear your word with backspace, and the direction arrows will reappear

**Q: What happens if I can't make a move?**
- Click **Pass** to skip your turn
- If both players pass consecutively, the game ends

**Q: Does the bot cheat?**
- No! The bot only sees the same grid you do and follows the same rules
- It picks from valid common words and occasionally makes suboptimal choices

**Q: How do I play faster?**
- Master keyboard navigation - it's much quicker than using the mouse
- Use arrow keys to move around, arrow keys to pick direction, and Enter to submit

---

**Ready to play?** Start your first game and see if you can outscore the AI! Remember: it's not just about vocabulary - strategy and placement matter just as much as knowing big words. Good luck! 🎮
