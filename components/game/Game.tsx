import { PieceData, getBlockCount } from '@/constants/Piece';
import { DndProvider, DndProviderProps, Rectangle } from '@mgcrea/react-native-dnd';
import React, { useEffect, useState } from 'react';
import { Platform, SafeAreaView, StyleSheet, View, Text } from 'react-native';
import { GestureHandlerRootView, State } from 'react-native-gesture-handler';
import Animated, { ReduceMotion, runOnJS, useSharedValue, FadeInUp, FadeOutUp, useAnimatedReaction } from 'react-native-reanimated';
import * as Haptics from 'expo-haptics';
import { Audio } from 'expo-av';
import { BoardBlockType, GRID_BLOCK_SIZE, JS_emptyPossibleBoardSpots, PossibleBoardSpots, XYPoint, breakLines, clearHoverBlocks, createPossibleBoardSpots, emptyPossibleBoardSpots, newEmptyBoard, placePieceOntoBoard, updateHoveredBreaks, canPlaceAnyPiece, deepCopyBoard } from '@/constants/Board';
import { StatsGameHud, StickyGameHud } from '@/components/game/GameHud';
import BlockGrid from '@/components/game/BlockGrid';
import { createHandWorklet, createRandomHand } from '@/constants/Hand';
import HandPieces from '@/components/game/HandPieces';
import { GameModeType, useSetAppState, MenuStateType } from '@/hooks/useAppState';
import { createHighScore, HighScoreId, updateHighScore } from '@/constants/Storage';
import { getRandomTemplate, applyTemplate } from '@/constants/Templates';

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
	
	const currentLevel = useSharedValue(1);
	const gemsCollected = useSharedValue(0);
	const gemsRequired = useSharedValue(5);

	const scoreStorageId = useSharedValue<HighScoreId | undefined>(undefined);
    const [encouragement, setEncouragement] = useState<string | null>(null);

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
                    // Resetting board for next level
					board.value = nextBoard;
                    hand.value = createHandWorklet(handSize, gameMode, nextBoard);
                    return;
				}
			}

			const pieceBlockCount = getBlockCount(piece);
			score.value += pieceBlockCount;
			if (linesBroken > 0) {
                runOnJS(playSound)('clear');
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

            // Check Game Over
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

                    <GameOverOverlay gameOver={gameOver} onRestart={() => setAppState(MenuStateType.MENU)} />
				</View>
			</GestureHandlerRootView>
		</SafeAreaView>
	);
})

function GameOverOverlay({ gameOver, onRestart }: { gameOver: SharedValue<boolean>, onRestart: () => void }) {
    const [visible, setVisible] = useState(false);
    
    useAnimatedReaction(() => gameOver.value, (cur) => {
        if (cur) runOnJS(setVisible)(true);
    });

    if (!visible) return null;

    return (
        <View style={styles.overlay}>
            <Text style={styles.gameOverText}>GAME OVER</Text>
            <Text style={styles.restartButton} onPress={onRestart}>MAIN MENU</Text>
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
        backgroundColor: 'rgba(0,0,0,0.8)', justifyContent: 'center', alignItems: 'center', zIndex: 3000
    },
    gameOverText: {
        fontFamily: 'Silkscreen', fontSize: 60, color: 'red', marginBottom: 20
    },
    restartButton: {
        fontFamily: 'Silkscreen', fontSize: 30, color: 'white', backgroundColor: 'blue', padding: 15, borderRadius: 10
    }
})

export default Game;