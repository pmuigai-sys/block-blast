import {
	Board,
	BoardBlockType,
	GRID_BLOCK_SIZE,
	HITBOX_SIZE,
	PossibleBoardSpots,
} from "@/constants/Board";
import { colorToHex } from "@/constants/Color";
import { Hand } from "@/constants/Hand";
import { useDroppable } from "@mgcrea/react-native-dnd";
import React, { useState } from "react";
import { StyleSheet, Text, View } from "react-native";
import Animated, {
	SharedValue,
	runOnJS,
	useAnimatedReaction,
	useAnimatedStyle,
	useSharedValue,
	withTiming,
    useDerivedValue,
} from "react-native-reanimated";
import BlockVisual from "./BlockVisual";

interface BlockGridProps {
	board: SharedValue<Board>;
	possibleBoardDropSpots: SharedValue<PossibleBoardSpots>;
	hand: SharedValue<Hand>
	draggingPiece: SharedValue<number | null>
}

function BlockCell({ x, y, board, possibleBoardDropSpots }: { x: number, y: number, board: SharedValue<Board>, possibleBoardDropSpots: SharedValue<PossibleBoardSpots> }) {
    // We must use a local shared value for the "last valid color" during the fall animation
    // because the board value will be EMPTY while the animation is still playing.
    const lastColor = useSharedValue(board.value[y][x].color);
    const lastHoverColor = useSharedValue(board.value[y][x].hoveredBreakColor);
    
    const placedBlockFall = useSharedValue(0);
    const placedBlockDirectionX = useSharedValue(0);
    const placedBlockDirectionY = useSharedValue(0);
    const placedBlockRotation = useSharedValue(0);

    // This state is only for gems/react-native text rendering which is slow anyway
    const [hasGem, setHasGem] = useState(board.value[y][x].hasGem);

    useAnimatedReaction(() => {
        return board.value[y][x];
    }, (cur, prev) => {
        if (cur.hasGem !== prev?.hasGem) {
            runOnJS(setHasGem)(cur.hasGem);
        }

        if (cur.blockType !== BoardBlockType.EMPTY) {
            lastColor.value = cur.color;
            lastHoverColor.value = cur.hoveredBreakColor;
        }
        
        // Handle clear animation
        if (cur.blockType == BoardBlockType.EMPTY && prev && (prev.blockType == BoardBlockType.FILLED || prev.blockType == BoardBlockType.HOVERED_BREAK_EMPTY || prev.blockType == BoardBlockType.HOVERED_BREAK_FILLED)) {
            const angle = Math.random() * Math.PI * 2;
            const distance = 250;
            const rotation = (Math.random() - 0.5) * Math.PI * 4;
            
            placedBlockDirectionX.value = Math.cos(angle) * distance;
            placedBlockDirectionY.value = Math.sin(angle) * distance;
            placedBlockRotation.value = rotation;
            
            placedBlockFall.value = withTiming(1, { 
                duration: 600 
            }, (finished) => {
                'worklet';
                if (finished) {
                    placedBlockFall.value = 0;
                }
            });
        }
    });

    const animatedStyle = useAnimatedStyle(() => {
        const block = board.value[y][x];
        
        if (placedBlockFall.value > 0) {
            let progress = placedBlockFall.value;
			progress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
            return {
                opacity: 1 - progress,
                zIndex: 10,
                transform: [
                    { scale: 1 - progress * 0.5 },
                    { translateX: placedBlockDirectionX.value * progress },
                    { translateY: placedBlockDirectionY.value * progress },
                    { rotate: `${placedBlockRotation.value * progress}rad` }
                ]
            }
        }

        return {
            opacity: block.blockType == BoardBlockType.HOVERED ? 0.4 : 1,
            transform: [],
            zIndex: block.blockType !== BoardBlockType.EMPTY ? 5 : 1,
        };
    });

    const visualProps = useDerivedValue(() => {
        const block = board.value[y][x];
        const isFilled = block.blockType !== BoardBlockType.EMPTY || placedBlockFall.value > 0;
        
        let color = block.color;
        if (block.blockType === BoardBlockType.HOVERED_BREAK_FILLED) {
            color = block.hoveredBreakColor;
        } else if (placedBlockFall.value > 0) {
            // Use cached color for falling blocks
            color = lastColor.value;
        }

        return {
            isFilled,
            color
        };
    });

    return (
        <View style={[styles.cellContainer, { top: y * GRID_BLOCK_SIZE, left: x * GRID_BLOCK_SIZE }]}>
            <AnimatedBlockWrapper visualProps={visualProps} animatedStyle={animatedStyle} />
            
            {hasGem && (
                <View style={StyleSheet.absoluteFill}>
                     <AnimatedGemWrapper board={board} x={x} y={y} />
                </View>
            )}

            <BlockDroppable
                x={x}
                y={y}
                style={styles.hitbox}
                possibleBoardDropSpots={possibleBoardDropSpots}
            />
        </View>
    );
}

// Separate component for the animated block to ensure pure Reanimated rendering
function AnimatedBlockWrapper({ visualProps, animatedStyle }: { visualProps: SharedValue<any>, animatedStyle: any }) {
    const internalStyle = useAnimatedStyle(() => {
        if (!visualProps.value.isFilled) {
            return { display: 'none' };
        }
        return { display: 'flex' };
    });

    return (
        <Animated.View style={[animatedStyle, internalStyle]}>
            <BlockVisualReanimated visualProps={visualProps} />
        </Animated.View>
    );
}

// Truly reactive BlockVisual that doesn't rely on JS state
function BlockVisualReanimated({ visualProps }: { visualProps: SharedValue<any> }) {
    const [color, setColor] = useState(visualProps.value.color);

    useAnimatedReaction(() => visualProps.value.color, (c) => {
        runOnJS(setColor)(c);
    });

    return <BlockVisual color={color} size={GRID_BLOCK_SIZE} />;
}

function AnimatedGemWrapper({ board, x, y }: { board: SharedValue<Board>, x: number, y: number }) {
    const gemStyle = useAnimatedStyle(() => {
        const block = board.value[y][x];
        const isFilled = block.blockType === BoardBlockType.FILLED;
        return {
            opacity: isFilled ? 0 : 1,
            display: isFilled ? 'none' : 'flex'
        };
    });

    return (
        <Animated.View style={[StyleSheet.absoluteFill, styles.gemContainer, gemStyle]}>
            <Text style={styles.gemText}>💎</Text>
        </Animated.View>
    );
}

export default function BlockGrid({
	board,
	possibleBoardDropSpots,
	draggingPiece,
	hand
}: BlockGridProps) {
	const boardLength = board.value.length;
    
    const gridLines = [];
    for (let y = 0; y < boardLength; y++) {
        for (let x = 0; x < boardLength; x++) {
            gridLines.push(
                <View key={`g${x},${y}`} style={[styles.gridLine, { 
                    top: y * GRID_BLOCK_SIZE, 
                    left: x * GRID_BLOCK_SIZE,
                    width: GRID_BLOCK_SIZE,
                    height: GRID_BLOCK_SIZE
                }]} />
            );
        }
    }

    const blockCells = [];
    for (let y = 0; y < boardLength; y++) {
        for (let x = 0; x < boardLength; x++) {
            blockCells.push(
                <BlockCell
                    key={`c${x},${y}`}
                    x={x}
                    y={y}
                    board={board}
                    possibleBoardDropSpots={possibleBoardDropSpots}
                />
            );
        }
    }
	
	const gridStyle = useAnimatedStyle(() => {
		let style: any;
		if (draggingPiece.value == null) {
			style = { borderColor: 'white' }
		} else {
            const piece = hand.value[draggingPiece.value!];
			style = { borderColor: piece ? colorToHex(piece.color) : 'white' }
		}
		return style;
	});
	
	return (
		<Animated.View
			style={[
				styles.grid,
				{
					width: GRID_BLOCK_SIZE * boardLength + 6,
					height: GRID_BLOCK_SIZE * boardLength + 6,
				},
				gridStyle
			]}
		>
            <View style={StyleSheet.absoluteFill}>{gridLines}</View>
			{blockCells}
		</Animated.View>
	);
}

interface BlockDroppableProps {
	children?: any;
	x: number;
	y: number;
	style: any;
	possibleBoardDropSpots: SharedValue<PossibleBoardSpots>;
}

function BlockDroppable({
	children,
	x,
	y,
	style,
	possibleBoardDropSpots,
	...otherProps
}: BlockDroppableProps) {
	const id = `${x},${y}`;
	const { props } = useDroppable({ id });

	const updateLayout = () => {
		setTimeout(() => { (props.onLayout as any)(null); }, 1000 / 60);
	};

	const animatedStyle = useAnimatedStyle(() => {
		runOnJS(updateLayout)();
		const active = possibleBoardDropSpots.value[y][x] == 1;
		return {
			width: active ? HITBOX_SIZE : 0,
			height: active ? HITBOX_SIZE : 0,
		};
	});

	return (
		<Animated.View {...props} style={[style, animatedStyle]} {...otherProps}>
			{children}
		</Animated.View>
	);
}

const styles = StyleSheet.create({
	cellContainer: {
		width: GRID_BLOCK_SIZE,
		height: GRID_BLOCK_SIZE,
		position: "absolute",
		justifyContent: "center",
		alignItems: "center",
	},
    gridLine: {
        position: 'absolute',
        borderWidth: 0.5,
        borderColor: 'rgba(255, 255, 255, 0.15)',
    },
	grid: {
		position: "relative",
		backgroundColor: "rgb(0, 0, 0, 1)",
		borderWidth: 3,
		borderRadius: 5,
		borderColor: "rgb(255, 255, 255)",
	},
	hitbox: {
		width: HITBOX_SIZE,
		height: HITBOX_SIZE,
        position: 'absolute',
	},
    gemContainer: {
        justifyContent: 'center',
        alignItems: 'center'
    },
    gemText: {
        fontSize: 20, 
        textAlign: 'center', 
        lineHeight: GRID_BLOCK_SIZE
    }
});
