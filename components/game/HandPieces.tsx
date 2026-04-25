import { DRAG_JUMP_LENGTH, GRID_BLOCK_SIZE, HAND_BLOCK_SIZE } from "@/constants/Board";
import { Hand } from "@/constants/Hand";
import { SharedPoint, useDraggable } from "@mgcrea/react-native-dnd";
import React, { useState } from 'react';
import { StyleSheet, View } from "react-native";
import Animated, { SharedValue, runOnJS, useAnimatedStyle, useAnimatedReaction } from "react-native-reanimated";
import BlockVisual from "./BlockVisual";

interface HandProps {
	hand: SharedValue<Hand>
}

function HandPieceItem({ index, hand }: { index: number, hand: SharedValue<Hand> }) {
    const id = String(index);
    const [pieceState, setPieceState] = useState(hand.value[index]);

    useAnimatedReaction(() => {
        return hand.value[index];
    }, (cur) => {
        runOnJS(setPieceState)(cur);
    });

    const pieceBlocks = [];
    if (pieceState) {
        const pieceHeight = pieceState.matrix.length;
        const pieceWidth = pieceState.matrix[0].length;
        for (let y = 0; y < pieceHeight; y++) {
            for (let x = 0; x < pieceWidth; x++) {
                if (pieceState.matrix[y][x] === 1) {
                    pieceBlocks.push(
                        <View key={`hp${x},${y}`} style={{
                            position: 'absolute',
                            top: y * GRID_BLOCK_SIZE,
                            left: x * GRID_BLOCK_SIZE,
                            width: GRID_BLOCK_SIZE,
                            height: GRID_BLOCK_SIZE
                        }}>
                            <BlockVisual color={pieceState.color} size={GRID_BLOCK_SIZE} />
                        </View>
                    );
                }
            }
        }
    }

    const createStyle = (dragging: boolean, acting: boolean, offset: SharedPoint, piece: any) => {
        "worklet";
        if (!piece) return { opacity: 0 };
        
        const pieceHeight = piece.matrix.length;
        const pieceWidth = piece.matrix[0].length;
        const zIndex = dragging ? 999 : acting ? 998 : 1;

        return {
            width: pieceWidth * GRID_BLOCK_SIZE,
            height: pieceHeight * GRID_BLOCK_SIZE,
            opacity: 1,
            zIndex,
            bottom: dragging ? DRAG_JUMP_LENGTH : 0,
            transform: [
                { translateX: dragging || acting ? offset.x.value : 0 },
                { translateY: dragging || acting ? offset.y.value : 0 },
                { scale: dragging ? 1 : HAND_BLOCK_SIZE / GRID_BLOCK_SIZE }
            ]
        };
    };

    return (
        <View style={styles.pieceContainer}>
            <PieceDraggable id={id} hand={hand} index={index} createStyle={createStyle}>
                {pieceBlocks}
            </PieceDraggable>
        </View>
    );
}

export default function HandPieces({ hand }: HandProps) {
	return (
        <View style={styles.hand}>
            {hand.value.map((_, i) => (
                <HandPieceItem key={i} index={i} hand={hand} />
            ))}
        </View>
    );
}

function PieceDraggable({ children, id, hand, index, createStyle }: any) {
	const { props, offset, state, setNodeLayout } = useDraggable({ id });

	const updateLayout = () => {
		(setNodeLayout as any)(null);
	}

	const animatedStyle = useAnimatedStyle(() => {
		runOnJS(updateLayout)();
		const isActive = state.value === "dragging";
		const isActing = state.value === "acting";
		return createStyle(isActive, isActing, offset, hand.value[index]);
	}, [state, hand]);

	return <Animated.View {...props} style={animatedStyle}>{children}</Animated.View>
}

const styles = StyleSheet.create({
	hand: {
		justifyContent: 'center',
		alignItems: 'center',
		flexDirection: 'row',
		position: 'relative',
		marginTop: 40,
		maxWidth: HAND_BLOCK_SIZE * 5 * 3,
		height: HAND_BLOCK_SIZE * 6,
		alignSelf: 'center',
	},
	pieceContainer: {
		width: HAND_BLOCK_SIZE * 5,
		height: HAND_BLOCK_SIZE * 5,
		position: 'relative',
		justifyContent: 'center',
		alignItems: 'center'
	}
})
