# Block Blast Redesign - Technical Design

## Architecture Overview

### Component Structure
```
AetherBlockBlastApp (Root)
├── GameController (State Management)
├── ModeSelectionScreen (Initial Screen)
└── GameScreen (Main Gameplay)
    ├── TopStatusBar
    ├── GameGrid (with 3D blocks)
    └── PieceTray (with 3D previews)
```

## Data Models

### GameMode Enum
```dart
enum GameMode {
  infinite,  // Guaranteed fitting pieces + prefilled grid
  classic,   // Random pieces + prefilled grid
  puzzle,    // Level progression + gem collection
}
```

### GameState
```dart
class GameState {
  GameMode? currentMode;
  int boardSize;
  List<List<GridCell>> board;
  List<Piece> offers;
  int? selectedOfferIndex;
  int score;
  int bestScore;
  int combo;
  int currentLevel;      // Puzzle mode
  int gemsCollected;     // Puzzle mode
  int gemsRequired;      // Puzzle mode
  bool gameOver;
}
```

### GridCell
```dart
class GridCell {
  bool isOccupied;
  Color? blockColor;
  bool hasGem;           // Puzzle mode
  int? templateId;       // For prefilled blocks
}
```

### PrefillTemplate
```dart
class PrefillTemplate {
  String id;
  int gridSize;
  List<Cell> prefilledCells;
  GameMode applicableMode;
}
```

## Game Mode Logic

### Infinite Mode
**Piece Generation Algorithm:**
```
1. Get all pieces from library
2. Filter pieces that fit on current grid
3. If fitting pieces < 3:
   - Select all fitting pieces
   - Fill remaining slots with smallest pieces
4. Else:
   - Rank fitting pieces by "future fit score"
   - Select top 5 candidates
   - Randomly pick 3 from candidates
5. Shuffle selected pieces
```

**Prefill Algorithm:**
```
1. Select random template for grid size
2. Place blocks according to template
3. Ensure template leaves room for initial pieces
4. Mark template as used (avoid repeats in session)
```

### Classic Mode
**Piece Generation Algorithm:**
```
1. Randomly select 3 pieces from library
2. No filtering or guarantees
3. Game over if none fit
```

**Prefill Algorithm:**
```
Same as Infinite mode
```

### Puzzle Mode
**Level Progression:**
```
Level 1-10:  6x6 grid, 3-5 gems required
Level 11-25: 8x8 grid, 5-8 gems required
Level 26-50: 10x10 grid, 8-12 gems required
```

**Gem Placement:**
```
1. Calculate gem positions based on level
2. Embed gems in specific grid cells
3. Gems collected when containing block cleared
4. Level complete when gemsCollected >= gemsRequired
```

## 3D Graphics Implementation

### Block3D Widget
**Rendering Approach:**
- CustomPainter for isometric projection
- Three faces: top, left, front
- Lighting simulation with color gradients

**Face Calculations:**
```dart
// Top face (lighter)
topColor = lighten(baseColor, 0.2)
topPath = [
  (0, depth),
  (depth, 0),
  (width, 0),
  (width-depth, depth)
]

// Left face (darker)
leftColor = darken(baseColor, 0.3)
leftPath = [
  (0, depth),
  (0, height),
  (depth, height-depth),
  (depth, 0)
]

// Front face (base color)
frontRect = (depth, 0, width-depth, height-depth)
```

### PiecePreview3D Widget
**Rendering:**
- Calculate piece bounds
- Center piece in preview area
- Render each cell as 3D block
- Scale to fit preview size

## UI Layout System

### Responsive Breakpoints
```
Mobile:  < 600px width
Tablet:  600-1200px width
Desktop: > 1200px width
```

### Layout Proportions
```
Top Bar:    80px fixed height
Game Grid:  Flexible (70% of remaining space)
Piece Tray: 120px fixed height
```

### Grid Sizing
```dart
gridSize = min(screenWidth, screenHeight * 0.7)
cellSize = gridSize / boardSize
minGridSize = 300px
maxGridSize = 800px
```

## Scoring System

### Base Scores
```
Piece Placement:
- 1 block:  10 pts
- 2 blocks: 25 pts
- 3 blocks: 45 pts
- 4 blocks: 70 pts
- 5+ blocks: 100 pts

Line Clears:
- 1 line:  100 pts
- 2 lines: 300 pts
- 3 lines: 600 pts
- 4+ lines: 1000 pts

Gems (Puzzle Mode):
- Per gem: 50 pts
```

### Multipliers
```
Combo Multiplier:
- 1st clear: x1.0
- 2nd clear: x1.5
- 3rd clear: x2.0
- 4th+ clear: x2.5 (max)

Speed Bonus:
- Move within 3 seconds: +10%
```

### Score Calculation
```dart
totalScore = (baseScore + clearScore) * comboMultiplier + speedBonus
```

## Audio System

### File Format Strategy
```
Primary: MP3 (universal browser support)
Fallback: OGG (older browsers)
Quality: 44.1kHz, 128kbps
```

### Sound Categories
```
Music:
- menu_music.mp3 (looped)
- gameplay_music.mp3 (looped)

SFX:
- piece_place.mp3
- line_clear.mp3
- multi_clear.mp3
- gem_collect.mp3
- level_complete.mp3
- game_over.mp3
- invalid_move.mp3

Voice:
- nice.mp3
- great.mp3
- awesome.mp3
- amazing.mp3
- perfect.mp3
```

### Audio Context Management
```dart
class AudioController {
  AudioPlayer musicPlayer;
  AudioPlayer sfxPlayer;
  AudioPlayer voicePlayer;
  
  Future<void> unlockAudio() {
    // Required for web browsers
    // Play silent audio on first user interaction
  }
  
  Future<void> playSound(String category, String name) {
    // Load from assets/audio/{category}/{name}.mp3
    // Handle errors gracefully
  }
}
```

## Prefill Template System

### Template Structure
```dart
class PrefillTemplate {
  String id;
  int gridSize;
  List<Cell> cells;
  
  static List<PrefillTemplate> templates = [
    // 8x8 templates
    PrefillTemplate(
      id: '8x8_corner',
      gridSize: 8,
      cells: [
        Cell(0, 0), Cell(0, 1),
        Cell(1, 0), Cell(7, 7),
      ],
    ),
    // ... more templates
  ];
}
```

### Template Selection
```dart
List<String> usedTemplates = [];

PrefillTemplate selectTemplate(int gridSize, GameMode mode) {
  var available = templates
    .where((t) => t.gridSize == gridSize)
    .where((t) => !usedTemplates.contains(t.id))
    .toList();
    
  if (available.isEmpty) {
    usedTemplates.clear();
    available = templates.where((t) => t.gridSize == gridSize).toList();
  }
  
  var selected = available[random.nextInt(available.length)];
  usedTemplates.add(selected.id);
  return selected;
}
```

## State Management

### GameController Methods
```dart
class GameController extends ChangeNotifier {
  // Mode management
  void selectMode(GameMode? mode);
  
  // Game lifecycle
  void startNewRun();
  void restartLevel(); // Puzzle mode
  
  // Piece management
  void selectOffer(int index);
  Future<void> placeSelectedAt(int row, int col);
  bool canPlaceAnywhere(Piece piece);
  
  // Scoring
  void updateScore(int delta);
  void incrementCombo();
  void resetCombo();
  
  // Puzzle mode
  void collectGem();
  void advanceLevel();
  
  // Persistence
  Future<void> save();
  Future<void> load();
}
```

### State Persistence
```dart
class PersistedSession {
  GameMode? currentMode;
  int currentLevel;
  int gemsCollected;
  List<String> usedTemplates;
  // ... existing fields
}
```

## Animation System

### Piece Placement Animation
```
Duration: 200ms
Easing: easeOutCubic
Effect: Scale from 0.8 to 1.0 + slight bounce
```

### Line Clear Animation
```
Duration: 300ms
Easing: easeInOutQuad
Effect: Fade out + scale down to 0
Sequence: Row/column highlights → fade → remove
```

### Gem Collection Animation
```
Duration: 500ms
Easing: easeOutBack
Effect: Gem flies from grid to counter
Path: Bezier curve
```

### Score Popup Animation
```
Duration: 1000ms
Easing: easeOutQuint
Effect: Float up + fade out
Position: Above cleared area
```

## Performance Optimizations

### Rendering
- Use `RepaintBoundary` for grid
- Cache piece preview painters
- Minimize widget rebuilds with `const` constructors
- Use `AnimatedBuilder` for selective updates

### Memory
- Dispose audio players properly
- Clear animation controllers
- Limit template cache size
- Reuse piece objects

### Computation
- Lazy evaluation for piece fitting
- Cache grid state checksums
- Debounce rapid user inputs
- Async operations for heavy calculations

## Testing Strategy

### Unit Tests
- Piece fitting algorithms
- Score calculations
- Grid state management
- Template selection logic

### Widget Tests
- UI component rendering
- User interactions
- Navigation flows
- Responsive layout

### Integration Tests
- Complete game flows
- Mode transitions
- Save/load functionality
- Audio playback

### Property-Based Tests
- Piece fitting guarantee (Infinite mode)
- Score monotonicity
- Grid state consistency
- Line clear correctness
- Gem collection accuracy

## Migration Strategy

### Phase 1: Core Infrastructure
1. Add GameMode enum and state
2. Implement 3D block widgets
3. Update GameController with mode support

### Phase 2: UI Redesign
1. Create ModeSelectionScreen
2. Redesign GameScreen layout
3. Implement new TopStatusBar
4. Update PieceTray with 3D previews

### Phase 3: Game Modes
1. Implement Infinite mode logic
2. Implement Classic mode logic
3. Implement Puzzle mode logic
4. Add prefill template system

### Phase 4: Polish
1. Update audio system
2. Add animations
3. Improve scoring feedback
4. Performance optimization

### Phase 5: Testing & Refinement
1. Run all tests
2. Fix bugs
3. Optimize performance
4. User testing feedback
