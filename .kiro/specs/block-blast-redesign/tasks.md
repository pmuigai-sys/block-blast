# Block Blast Redesign - Implementation Tasks

## Phase 1: Core Infrastructure

### 1.1 Add Game Mode System
- [ ] Add `GameMode` enum (infinite, classic, puzzle)
- [ ] Add `currentMode` field to GameController
- [ ] Add `selectMode()` method
- [ ] Update PersistedSession to include mode
- [ ] Add mode-specific state fields (level, gems, etc.)

### 1.2 Implement 3D Block Widgets
- [ ] Create `Block3D` widget with CustomPainter
- [ ] Implement isometric rendering (top, left, front faces)
- [ ] Add lighting simulation (lighten/darken colors)
- [ ] Create `Block3DPainter` class
- [ ] Add color constants for 6 block colors

### 1.3 Implement 3D Piece Preview
- [ ] Create `PiecePreview3D` widget
- [ ] Create `PiecePreview3DPainter` class
- [ ] Calculate piece bounds and centering
- [ ] Render each cell as 3D block
- [ ] Add selection and drag states

## Phase 2: UI Redesign

### 2.1 Create Mode Selection Screen
- [ ] Create `ModeSelectionScreen` widget
- [ ] Add mode cards with icons and descriptions
- [ ] Implement mode selection navigation
- [ ] Add gradient background
- [ ] Style with Crystal Blocks theme

### 2.2 Redesign Game Screen Layout
- [ ] Replace complex layout with Column structure
- [ ] Implement top status bar (80px fixed)
- [ ] Implement game grid (70% flexible)
- [ ] Implement piece tray (120px fixed)
- [ ] Remove side rail and old UI elements

### 2.3 Implement Top Status Bar
- [ ] Add score display
- [ ] Add best score display
- [ ] Add level/gems display (puzzle mode)
- [ ] Add mode indicator badge
- [ ] Add menu button

### 2.4 Redesign Game Grid
- [ ] Simplify grid container styling
- [ ] Integrate Block3D widgets
- [ ] Update drag-and-drop handling
- [ ] Improve grid sizing logic
- [ ] Add proper shadows and borders

### 2.5 Redesign Piece Tray
- [ ] Use PiecePreview3D widgets
- [ ] Remove piece name labels
- [ ] Improve selection visual feedback
- [ ] Enhance drag feedback
- [ ] Simplify layout to horizontal row

### 2.6 Create Game Menu
- [ ] Create modal bottom sheet menu
- [ ] Add "New Game" option
- [ ] Add "Change Mode" option
- [ ] Add "Settings" option
- [ ] Style with theme colors

### 2.7 Update Settings Screen
- [ ] Simplify settings modal
- [ ] Keep grid size selection
- [ ] Keep audio toggles
- [ ] Remove complex options
- [ ] Improve visual design

## Phase 3: Game Mode Implementation

### 3.1 Implement Prefill Template System
- [ ] Create `PrefillTemplate` class
- [ ] Define 10+ templates for 6x6 grid
- [ ] Define 10+ templates for 8x8 grid
- [ ] Define 10+ templates for 10x10 grid
- [ ] Implement template selection logic
- [ ] Add template usage tracking (avoid repeats)

### 3.2 Implement Infinite Mode
- [ ] Update piece generation to guarantee fitting
- [ ] Implement "future fit score" algorithm
- [ ] Apply prefill template on game start
- [ ] Ensure at least one piece always fits
- [ ] Test with various grid states

### 3.3 Implement Classic Mode
- [ ] Implement random piece generation
- [ ] Apply prefill template on game start
- [ ] Remove fitting guarantees
- [ ] Implement proper game over detection
- [ ] Test traditional difficulty

### 3.4 Implement Puzzle Mode Base
- [ ] Add level progression system (1-50)
- [ ] Define level configurations
- [ ] Implement level advancement logic
- [ ] Add level-specific grid sizes
- [ ] Create level selection/display

### 3.5 Implement Gem System
- [ ] Add `hasGem` field to GridCell
- [ ] Implement gem placement algorithm
- [ ] Add gem collection on clear
- [ ] Update gem counter display
- [ ] Add gem collection animation

### 3.6 Implement Puzzle Level Completion
- [ ] Check gems collected vs required
- [ ] Show level complete overlay
- [ ] Advance to next level
- [ ] Save level progress
- [ ] Add celebration effects

## Phase 4: Scoring & Feedback

### 4.1 Update Scoring System
- [ ] Implement base placement scores (10-100 pts)
- [ ] Implement line clear scores (100-1000 pts)
- [ ] Implement combo multipliers (x1.5-x2.5)
- [ ] Add speed bonus calculation
- [ ] Ensure minimum 10 pts on first piece

### 4.2 Add Score Feedback
- [ ] Create floating score popup widget
- [ ] Show score delta on placement
- [ ] Show encouragement text (Nice, Great, etc.)
- [ ] Animate score changes
- [ ] Add visual effects for big scores

### 4.3 Update Praise System
- [ ] Simplify praise messages
- [ ] Remove technical jargon
- [ ] Add appropriate triggers
- [ ] Improve visual presentation
- [ ] Add sound effects

## Phase 5: Audio System

### 5.1 Convert Audio Files
- [ ] Convert all audio to MP3 format
- [ ] Ensure 44.1kHz, 128kbps quality
- [ ] Create OGG fallbacks if needed
- [ ] Test file sizes
- [ ] Verify web compatibility

### 5.2 Update Audio Controller
- [ ] Improve web audio context handling
- [ ] Add proper audio unlocking
- [ ] Implement graceful error handling
- [ ] Add audio loading states
- [ ] Test on all platforms

### 5.3 Add New Sound Effects
- [ ] Add gem collection sound
- [ ] Add level complete sound
- [ ] Improve line clear sound
- [ ] Add combo sound effects
- [ ] Test sound timing

### 5.4 Update Voice Feedback
- [ ] Record/source new voice clips
- [ ] Simplify praise vocabulary
- [ ] Improve voice playback timing
- [ ] Add volume normalization
- [ ] Test voice clarity

## Phase 6: Animations

### 6.1 Piece Placement Animation
- [ ] Add scale animation on placement
- [ ] Add bounce effect
- [ ] Set duration to 200ms
- [ ] Use easeOutCubic easing
- [ ] Test smoothness

### 6.2 Line Clear Animation
- [ ] Add highlight effect
- [ ] Add fade out animation
- [ ] Add scale down effect
- [ ] Set duration to 300ms
- [ ] Sequence animations properly

### 6.3 Gem Collection Animation
- [ ] Create gem fly-to-counter animation
- [ ] Use Bezier curve path
- [ ] Add sparkle effects
- [ ] Set duration to 500ms
- [ ] Test visual appeal

### 6.4 Score Popup Animation
- [ ] Create floating text widget
- [ ] Add upward movement
- [ ] Add fade out effect
- [ ] Set duration to 1000ms
- [ ] Position above cleared area

### 6.5 Level Complete Animation
- [ ] Add screen flash effect
- [ ] Add confetti particles
- [ ] Add celebration sound
- [ ] Show level complete overlay
- [ ] Transition to next level

## Phase 7: Polish & Optimization

### 7.1 Performance Optimization
- [ ] Add RepaintBoundary to grid
- [ ] Cache piece preview painters
- [ ] Minimize widget rebuilds
- [ ] Profile frame rates
- [ ] Optimize heavy computations

### 7.2 Responsive Design
- [ ] Test on mobile devices
- [ ] Test on tablets
- [ ] Test on desktop
- [ ] Adjust touch targets
- [ ] Verify grid scaling

### 7.3 Accessibility
- [ ] Test high contrast mode
- [ ] Test reduced motion
- [ ] Verify touch target sizes
- [ ] Test with screen readers
- [ ] Add colorblind support

### 7.4 Visual Polish
- [ ] Refine color palette
- [ ] Improve shadows and lighting
- [ ] Add subtle particle effects
- [ ] Polish transitions
- [ ] Ensure consistent styling

### 7.5 Bug Fixes
- [ ] Fix any drag-and-drop issues
- [ ] Fix audio playback bugs
- [ ] Fix state persistence issues
- [ ] Fix animation glitches
- [ ] Fix layout issues

## Phase 8: Testing

### 8.1 Unit Tests
- [ ] Test piece fitting algorithms
- [ ] Test score calculations
- [ ] Test grid state management
- [ ] Test template selection
- [ ] Test gem collection logic

### 8.2 Widget Tests
- [ ] Test ModeSelectionScreen
- [ ] Test GameScreen layout
- [ ] Test TopStatusBar
- [ ] Test GameGrid interactions
- [ ] Test PieceTray

### 8.3 Integration Tests
- [ ] Test complete game flow (Infinite)
- [ ] Test complete game flow (Classic)
- [ ] Test complete game flow (Puzzle)
- [ ] Test mode switching
- [ ] Test save/load

### 8.4 Property-Based Tests
- [ ] Test piece fitting guarantee
- [ ] Test score monotonicity
- [ ] Test grid consistency
- [ ] Test line clear correctness
- [ ] Test gem collection accuracy

### 8.5 Platform Testing
- [ ] Test on Chrome (web)
- [ ] Test on Firefox (web)
- [ ] Test on Safari (web)
- [ ] Test on Android
- [ ] Test on iOS
- [ ] Test on Windows desktop
- [ ] Test on Mac desktop

## Phase 9: Documentation

### 9.1 Update README
- [ ] Document new game modes
- [ ] Update feature list
- [ ] Add screenshots
- [ ] Update build instructions
- [ ] Document audio requirements

### 9.2 Code Documentation
- [ ] Add doc comments to new classes
- [ ] Document complex algorithms
- [ ] Add usage examples
- [ ] Document state management
- [ ] Document audio system

### 9.3 User Guide
- [ ] Create mode descriptions
- [ ] Explain scoring system
- [ ] Document controls
- [ ] Add tips and strategies
- [ ] Create FAQ

## Phase 10: Deployment

### 10.1 Build Verification
- [ ] Run `flutter analyze`
- [ ] Run all tests
- [ ] Build web version
- [ ] Build Android APK
- [ ] Build iOS app
- [ ] Build desktop apps

### 10.2 Performance Verification
- [ ] Measure load times
- [ ] Verify 60 FPS gameplay
- [ ] Check memory usage
- [ ] Test battery impact (mobile)
- [ ] Verify audio latency

### 10.3 Final QA
- [ ] Complete playthrough (all modes)
- [ ] Test edge cases
- [ ] Verify all features work
- [ ] Check for visual glitches
- [ ] Verify audio quality

### 10.4 Release Preparation
- [ ] Update version number
- [ ] Create release notes
- [ ] Prepare app store assets
- [ ] Create promotional materials
- [ ] Plan release timeline
