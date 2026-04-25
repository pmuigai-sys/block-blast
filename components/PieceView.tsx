import React from 'react';
import { PieceData } from "@/constants/Piece";
import { View, StyleSheet } from "react-native";
import BlockVisual from "./game/BlockVisual";

interface PieceViewProps {
    piece: PieceData;
    blockSize: number;
    style?: any;
    isGhost?: boolean;
}

export function PieceView({ piece, blockSize, style, isGhost = false }: PieceViewProps) {
    const pieceHeight = piece.matrix.length;
    const pieceWidth = piece.matrix[0].length;
    const pieceBlocks = [];

    for (let y = 0; y < pieceHeight; y++) {
        for (let x = 0; x < pieceWidth; x++) {
            if (piece.matrix[y][x] == 1) {
                pieceBlocks.push(
                    <View
                        key={`${x},${y}`}
                        style={{
                            width: blockSize,
                            height: blockSize,
                            top: y * blockSize,
                            left: x * blockSize,
                            position: "absolute",
                        }}
                    >
                        <BlockVisual color={piece.color} size={blockSize} isGhost={isGhost} />
                    </View>,
                );
            }
        }
    }

    return (
        <View style={[
            {
                width: pieceWidth * blockSize,
                height: pieceHeight * blockSize
            },
            style
        ]}>
            {pieceBlocks}
        </View>
    );
}
