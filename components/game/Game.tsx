import { getBlockCount } from '@/constants/Piece';
import { DndProvider, DndProviderProps, Rectangle } from '@mgcrea/react-native-dnd';
import React, { useEffect, useState } from 'react';
import { Platform, SafeAreaView, StyleSheet, View, Text, Modal, Pressable } from 'react-native';
import { GestureHandlerRootView, State } from 'react-native-gesture-handler';
import Animated, { ReduceMotion, runOnJS, useSharedValue, FadeInUp, FadeOutUp, useAnimatedReaction } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import { GRID_BLOCK_SIZE, JS_emptyPossibleBoardSpots, PossibleBoardSpots, breakLines, clearHoverBlocks, createPossibleBoardSpots, emptyPossibleBoardSpots, newEmptyBoard, placePieceOntoBoard, updateHoveredBreaks, canPlaceAnyPiece, deepCopyBoard } from '@/constants/Board';
import { BoardBlockType, XYPoint, PieceData } from '@/constants/Types';
import { StatsGameHud, StickyGameHud } from '@/components/game/GameHud';
import BlockGrid from '@/components/game/BlockGrid';
import { createHandWorklet, createRandomHand } from '@/constants/Hand';
import HandPieces from '@/components/game/HandPieces';
import { GameModeType, useSetAppState, MenuStateType } from '@/hooks/useAppState';
import { createHighScore, HighScoreId, updateHighScore } from '@/constants/Storage';
import { getRandomTemplate, applyTemplate } from '@/constants/Templates';
import { playVoiceReward } from '@/components/AudioController';

const pieceOverlapsRectangle = (layout: Rectangle, other: Rectangle) => {
	"worklet";
	if (other.width == 0 && other.height == 0) return false;
	return (
		layout.x < other.x + other.width &&
		layout.x + GRID_BLOCK_SIZE > other.x &&
		layout.y < other.y + other.height &&
		layout.y + GRID_BLOCK_SIZE > other.y
	);
};

const SPRING_CONFIG_MISSED_DRAG = {
	mass: 1, damping: 1, stiffness: 500, overshootClamping: true,
	restDisplacementThreshold: 0.01, restSpeedThreshold: 0.01, reduceMotion: ReduceMotion.Never,
}

function decodeDndId(id: string): XYPoint {
	"worklet";
    const parts = id.split(',');
    if (parts.length === 2) {
	    return {x: Number(parts[0]), y: Number(parts[1])}
    }
	return {x: Number(id[0]), y: Number(id[2])}
}

function impactAsyncHelper(style: Haptics.ImpactFeedbackStyle) {
	Haptics.impactAsync(style);
}

function runPiecePlacedHaptic() {
	"worklet";
	runOnJS(impactAsyncHelper)(Haptics.ImpactFeedbackStyle.Light);
}

export const Game = (({gameMode}: {gameMode: GameModeType}) => {
	const boardLength = gameMode === GameModeType.Puzzle ? 6 : 8;
	const handSize = 3;
    const [ setAppState ] = useSetAppState();
	
	const board = useSharedValue(newEmptyBoard(boardLength));
	const draggingPiece = useSharedValue<number | null>(null);
	const possibleBoardDropSpots = useSharedValue<PossibleBoardSpots>(JS_emptyPossibleBoardSpots(boardLength));
	const hand = useSharedValue(createRandomHand(handSize));
	const score = useSharedValue(0);
	const combo = useSharedValue(0);
	const lastBrokenLine = useSharedValue(0);
	const gameOver = useSharedValue(false);
    const totalBlocksPlaced = useSharedValue(0);
	
	const currentLevel = useSharedValue(1);
	const gemsCollected = useSharedValue(0);
	const gemsRequired = useSharedValue(5);

	const scoreStorageId = useSharedValue<HighScoreId | undefined>(undefined);
    const [encouragement, setEncouragement] = useState<string | null>(null);
    const [showOnboarding, setShowOnboarding] = useState(true);

    const playSound = async (type: 'place' | 'clear' | 'gameover') => {
        try {
            let file;
            if (type === 'place') file = require('../../assets/audio/sfx/place.wav');
            else if (type === 'clear') file = require('../../assets/audio/sfx/clear.wav');
            else if (type === 'gameover') file = require('../../assets/audio/sfx/game_over.wav');
            
            if (file) {
                const { sound } = await Audio.Sound.createAsync(file);
                await sound.playAsync();
            }
        } catch (e) {
            console.warn("Audio play error", e);
        }
    };

    const showEncouragement = (lines: number) => {
        const texts = ["Nice!", "Great!", "Amazing!", "Incredible!", "PERFECT!"];
        const text = texts[Math.min(lines - 1, texts.length - 1)];
        setEncouragement(text);
        setTimeout(() => setEncouragement(null), 1500);
    };

	useEffect(() => {
        const initialBoard = newEmptyBoard(boardLength);
		if (gameMode !== GameModeType.Puzzle) {
			const template = getRandomTemplate(boardLength);
			if (template) {
				applyTemplate(initialBoard, template);
			}
		} else {
			for (let i = 0; i < 5; i++) {
				const rx = Math.floor(Math.random() * boardLength);
				const ry = Math.floor(Math.random() * boardLength);
				initialBoard[ry][rx].hasGem = true;
				initialBoard[ry][rx].blockType = BoardBlockType.FILLED;
			}
		}
        board.value = initialBoard;
		hand.value = createHandWorklet(handSize, gameMode, initialBoard);

		createHighScore({score: score.value, date: new Date().getTime(), type: gameMode}).then((id) => {
			scoreStorageId.value = id;
		});
	}, []);

	const handleDragEnd: DndProviderProps["onDragEnd"] = ({ active, over }) => {
		"worklet";
		if (over) {
			if (draggingPiece.value == null) return;

			const dropIdStr = over.id.toString();
			const {x: dropX, y: dropY} = decodeDndId(dropIdStr);
			const piece: PieceData = hand.value[draggingPiece.value!]!;

			if (Platform.OS != 'web') runPiecePlacedHaptic();
            runOnJS(playSound)('place');

			const newBoard = deepCopyBoard(clearHoverBlocks(board.value));
			placePieceOntoBoard(newBoard, piece, dropX, dropY, BoardBlockType.FILLED)
			const { lines: linesBroken, gems } = breakLines(newBoard);
			
			if (gameMode === GameModeType.Puzzle) {
				gemsCollected.value += gems;
				if (gemsCollected.value >= gemsRequired.value) {
					currentLevel.value += 1;
					gemsCollected.value = 0;
					gemsRequired.value += 2;
					const nextBoard = newEmptyBoard(boardLength);
					for (let i = 0; i < gemsRequired.value; i++) {
						const rx = Math.floor(Math.random() * boardLength);
						const ry = Math.floor(Math.random() * boardLength);
						nextBoard[ry][rx].hasGem = true;
						nextBoard[ry][rx].blockType = BoardBlockType.FILLED;
					}
					board.value = nextBoard;
                    hand.value = createHandWorklet(handSize, gameMode, nextBoard);
                    return;
				}
			}

			const pieceBlockCount = getBlockCount(piece);
			score.value += pieceBlockCount;
            totalBlocksPlaced.value += 1;

			if (linesBroken > 0) {
                runOnJS(playSound)('clear');
                runOnJS(playVoiceReward)(linesBroken);
                runOnJS(showEncouragement)(linesBroken);
				lastBrokenLine.value = 0;
				combo.value += linesBroken;
				score.value += linesBroken * boardLength * (combo.value / 2) * pieceBlockCount;
			} else {
				lastBrokenLine.value++;
				if (lastBrokenLine.value >= handSize) combo.value = 0;
			}
			if (scoreStorageId.value)
				runOnJS(updateHighScore)(scoreStorageId.value!, {score: score.value, date: new Date().getTime(), type: gameMode});
			
			const newHand = [...hand.value];
			newHand[draggingPiece.value!] = null;

			let empty = true
			for (let i = 0; i < handSize; i++) {
				if (newHand[i] != null) { empty = false; break; }
			}
			if (empty) {
				hand.value = createHandWorklet(handSize, gameMode, newBoard);
			} else {
				hand.value = newHand;
			}
			board.value = newBoard;

            if (!canPlaceAnyPiece(newBoard, hand.value)) {
                gameOver.value = true;
                runOnJS(playSound)('gameover');
            }
		} else {
			board.value = deepCopyBoard(clearHoverBlocks(board.value));
		}
		draggingPiece.value = null;
		possibleBoardDropSpots.value = emptyPossibleBoardSpots(boardLength);
	};

	const handleBegin: DndProviderProps["onBegin"] = (event, meta) => {
		"worklet";
		const handIndex = Number(meta.activeId.toString());
		if (hand.value[handIndex] != null) {
			draggingPiece.value = handIndex;
			possibleBoardDropSpots.value = createPossibleBoardSpots(board.value, hand.value[handIndex]);
		}
	};

	const handleFinalize: DndProviderProps["onFinalize"] = ({ state }) => {
		"worklet";
		if (state !== State.END) draggingPiece.value = null;
	};

	const handleUpdate: DndProviderProps["onUpdate"] = (event, {activeId, activeLayout, droppableActiveId}) => {
		"worklet";
		if (!droppableActiveId) {
			board.value = deepCopyBoard(clearHoverBlocks(board.value));
			return;
		}
		if (draggingPiece.value == null) return;
		const dropIdStr = droppableActiveId.toString();
		const {x: dropX, y: dropY} = decodeDndId(dropIdStr);
		const piece: PieceData = hand.value[draggingPiece.value!]!;
		const newBoard = deepCopyBoard(clearHoverBlocks(board.value));
		updateHoveredBreaks(newBoard, piece, dropX, dropY);
		board.value = newBoard
	}
	
	return (        
		<SafeAreaView style={styles.root}>
			<GestureHandlerRootView style={styles.root}>
				<View style={styles.root}>
					<StickyGameHud gameMode={gameMode} score={score}></StickyGameHud>
					<DndProvider shouldDropWorklet={pieceOverlapsRectangle} springConfig={SPRING_CONFIG_MISSED_DRAG} onBegin={handleBegin} onFinalize={handleFinalize} onDragEnd={handleDragEnd} onUpdate={handleUpdate}>
						<StatsGameHud score={score} combo={combo} lastBrokenLine={lastBrokenLine} hand={hand} level={currentLevel} gems={gemsCollected} gemsRequired={gemsRequired} gameMode={gameMode}></StatsGameHud>
						<BlockGrid board={board} possibleBoardDropSpots={possibleBoardDropSpots} hand={hand} draggingPiece={draggingPiece}></BlockGrid>
						<HandPieces hand={hand}></HandPieces>
					</DndProvider>

                    {encouragement && (
                        <Animated.View entering={FadeInUp} exiting={FadeOutUp} style={styles.encouragementContainer}>
                            <Text style={styles.encouragementText}>{encouragement}</Text>
                        </Animated.View>
                    )}

                    <Onboarding mode={gameMode} visible={showOnboarding} onDismiss={() => setShowOnboarding(false)} />
                    <GameOverOverlay gameOver={gameOver} onRestart={() => setAppState(MenuStateType.MENU)} gameMode={gameMode} blocksPlaced={totalBlocksPlaced} score={score} />
				</View>
			</GestureHandlerRootView>
		</SafeAreaView>
	);
})

function Onboarding({ mode, visible, onDismiss }: { mode: GameModeType, visible: boolean, onDismiss: () => void }) {
    const getContent = () => {
        switch(mode) {
            case GameModeType.Infinite:
                return {
                    title: "Infinite Rules",
                    text: "Every hand is guaranteed playable by our engine. Your only challenge is to try and fail. Can you even reach a game over?"
                };
            case GameModeType.Classic:
                return {
                    title: "Classic Rules",
                    text: "Traditional block blast. Random pieces, clear lines to survive as long as possible. Strategic planning is key."
                };
            case GameModeType.Puzzle:
                return {
                    title: "Puzzle Rules",
                    text: "Collect gems hidden within blocks to level up. Clear lines containing gems to advance."
                };
        }
    };

    const content = getContent();

    return (
        <Modal transparent visible={visible} animationType="fade">
            <View style={styles.modalBg}>
                <View style={styles.onboardingCard}>
                    <Text style={styles.onboardingTitle}>{content.title}</Text>
                    <Text style={styles.onboardingText}>{content.text}</Text>
                    <Pressable style={styles.dismissButton} onPress={onDismiss}>
                        <Text style={styles.dismissText}>I'M READY</Text>
                    </Pressable>
                </View>
            </View>
        </Modal>
    );
}

function GameOverOverlay({ gameOver, onRestart, gameMode, blocksPlaced, score }: { gameOver: SharedValue<boolean>, onRestart: () => void, gameMode: GameModeType, blocksPlaced: SharedValue<number>, score: SharedValue<number> }) {
    const [visible, setVisible] = useState(false);
    const [blocks, setBlocks] = useState(0);
    const [finalScore, setFinalScore] = useState(0);
    
    useAnimatedReaction(() => [gameOver.value, blocksPlaced.value, score.value], ([isOver, b, s]) => {
        if (isOver) {
            runOnJS(setBlocks)(b as number);
            runOnJS(setFinalScore)(s as number);
            runOnJS(setVisible)(true);
        }
    });

    if (!visible) return null;

    const calculateIQ = () => {
        const isInfinite = gameMode === GameModeType.Infinite;
        
        if (isInfinite) {
            if (finalScore < 100) return "Celestial Entity";
            if (finalScore < 500) return "Aether Entity";
            if (finalScore < 1000) return "Human (Strategist)";
            if (finalScore < 3000) return "Primate";
            return "Bird";
        } else {
            if (finalScore < 100) return "Bird";
            if (finalScore < 500) return "Primate";
            if (finalScore < 2000) return "Human";
            if (finalScore < 5000) return "Aether Entity";
            return "Celestial Entity";
        }
    };

    const isInfinite = gameMode === GameModeType.Infinite;

    return (
        <View style={styles.overlay}>
            <Text style={styles.gameOverText}>
                {isInfinite ? "CONGRATULATIONS!" : "GAME OVER"}
            </Text>
            {isInfinite && (
                <Text style={styles.loopBeatenText}>YOU BEAT THE INFINITE LOOP</Text>
            )}
            
            <View style={styles.statsContainer}>
                <Text style={styles.statText}>Blocks Placed: {blocks}</Text>
                <Text style={styles.statText}>Score: {finalScore}</Text>
                <Text style={styles.statText}>IQ Rating: <Text style={{color: 'cyan'}}>{calculateIQ()}</Text></Text>
            </View>

            <Pressable style={styles.restartButtonPressable} onPress={onRestart}>
                <Text style={styles.restartButtonText}>MAIN MENU</Text>
            </Pressable>
        </View>
    );
}

const styles = StyleSheet.create({
	root: {
		width: '100%', flex: 1, justifyContent: 'center', alignItems: 'center',
		padding: 0, overflow: 'hidden', backgroundColor: 'rgba(0, 0, 0, 0.4)' 
	},
    encouragementContainer: {
        position: 'absolute', top: 150, zIndex: 2000,
    },
    encouragementText: {
        fontFamily: 'Silkscreen', fontSize: 40, color: 'yellow',
        textShadowColor: 'black', textShadowOffset: { width: 2, height: 2 }, textShadowRadius: 5
    },
    overlay: {
        ...StyleSheet.absoluteFillObject,
        backgroundColor: 'rgba(0,0,0,0.9)', justifyContent: 'center', alignItems: 'center', zIndex: 3000
    },
    gameOverText: {
        fontFamily: 'Silkscreen', fontSize: 48, color: 'red', marginBottom: 10, textAlign: 'center'
    },
    loopBeatenText: {
        fontFamily: 'Silkscreen', fontSize: 18, color: '#00ff00', marginBottom: 30, textAlign: 'center', paddingHorizontal: 20
    },
    statsContainer: {
        marginBottom: 40, alignItems: 'center'
    },
    statText: {
        fontFamily: 'Silkscreen', fontSize: 20, color: 'white', marginBottom: 10
    },
    restartButtonPressable: {
        backgroundColor: 'blue', padding: 15, borderRadius: 10, borderWidth: 2, borderColor: 'white'
    },
    restartButtonText: {
        fontFamily: 'Silkscreen', fontSize: 24, color: 'white'
    },
    modalBg: {
        flex: 1, backgroundColor: 'rgba(0,0,0,0.7)', justifyContent: 'center', alignItems: 'center'
    },
    onboardingCard: {
        width: '80%', backgroundColor: '#222', padding: 30, borderRadius: 20, borderWidth: 2, borderColor: 'rgba(255,255,255,0.2)', alignItems: 'center'
    },
    onboardingTitle: {
        fontFamily: 'Silkscreen', fontSize: 24, color: 'white', marginBottom: 20
    },
    onboardingText: {
        fontFamily: 'Silkscreen', fontSize: 14, color: '#ccc', textAlign: 'center', marginBottom: 30, lineHeight: 22
    },
    dismissButton: {
        backgroundColor: '#00ff00', paddingVertical: 12, paddingHorizontal: 40, borderRadius: 10
    },
    dismissText: {
        fontFamily: 'Silkscreen', fontSize: 18, color: 'black'
    }
})

export default Game;