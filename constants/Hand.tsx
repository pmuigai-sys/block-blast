import { PieceData, Board, BoardBlockType } from "./Types";
import { getRandomPieceWorklet, getFittingPieceWorklet, piecesData, getRandomPiece } from "./Piece";
import { GameModeType } from "@/hooks/useAppState";
import { deepCopyBoard, placePieceOntoBoard, breakLines } from "./Board";

export type Hand = (PieceData | null)[]

export function createRandomHand(size: number): Hand {
	const hand = new Array<PieceData | null>(size);
	for (let i = 0; i < size; i++) {
		hand[i] = getRandomPiece();
	}
	return hand;
}

/**
 * Advanced Simulation Engine for Aether Infinite Mode
 */

function canFit(board: Board, piece: PieceData, x: number, y: number): boolean {
    "worklet";
    const pieceHeight = piece.matrix.length;
    const pieceWidth = piece.matrix[0].length;
    if (y + pieceHeight > board.length || x + pieceWidth > board[0].length) return false;

    for (let py = 0; py < pieceHeight; py++) {
        for (let px = 0; px < pieceWidth; px++) {
            if (piece.matrix[py][px] === 1 && board[y + py][x + px].blockType === BoardBlockType.FILLED) {
                return false;
            }
        }
    }
    return true;
}

function getValidPlacements(board: Board, piece: PieceData): {x: number, y: number}[] {
    "worklet";
    const placements = [];
    const boardLength = board.length;
    const pieceHeight = piece.matrix.length;
    const pieceWidth = piece.matrix[0].length;

    for (let y = 0; y <= boardLength - pieceHeight; y++) {
        for (let x = 0; x <= boardLength - pieceWidth; x++) {
            if (canFit(board, piece, x, y)) {
                placements.push({x, y});
            }
        }
    }
    return placements;
}

function isOrderPlayable(board: Board, pieces: PieceData[]): boolean {
    "worklet";
    if (pieces.length === 0) return true;
    
    const placements = getValidPlacements(board, pieces[0]);
    if (placements.length === 0) return false;

    // Pick a path that tries to keep the board clean.
    const bestPlacement = placements[0]; 
    
    const nextBoard = deepCopyBoard(board);
    placePieceOntoBoard(nextBoard, pieces[0], bestPlacement.x, bestPlacement.y, BoardBlockType.FILLED);
    breakLines(nextBoard);
    
    return isOrderPlayable(nextBoard, pieces.slice(1));
}

/**
 * Checks if a hand is "Stupid-Proof":
 * 1. Must be playable in ALL 6 permutations.
 */
function isHandIndestructible(board: Board, hand: PieceData[]): boolean {
    "worklet";
    const perms = [
        [hand[0], hand[1], hand[2]],
        [hand[0], hand[2], hand[1]],
        [hand[1], hand[0], hand[2]],
        [hand[1], hand[2], hand[0]],
        [hand[2], hand[0], hand[1]],
        [hand[2], hand[1], hand[0]]
    ];

    for (const p of perms) {
        if (!isOrderPlayable(board, p)) return false;
    }
    return true;
}

/**
 * Heuristic to check if pieces are "appropriate" for the board density.
 */
function getBoardDensity(board: Board): number {
    "worklet";
    let filled = 0;
    const total = board.length * board.length;
    for (let y = 0; y < board.length; y++) {
        for (let x = 0; x < board.length; x++) {
            if (board[y][x].blockType === BoardBlockType.FILLED) filled++;
        }
    }
    return filled / total;
}

function getRandomPieceColorWorklet() {
    "worklet";
    const pieceColors = [
        { r: 227, g: 143, b: 16 },
        { r: 186, g: 19, b: 38 },
        { r: 16, g: 158, b: 40 },
        { r: 20, g: 56, b: 184 },
        { r: 101, g: 19, b: 148 },
        { r: 31, g: 165, b: 222 }
    ];
    return pieceColors[Math.floor(Math.random() * pieceColors.length)];
}

export function createHandWorklet(size: number, mode: GameModeType, board?: Board): Hand {
	"worklet";
	const hand = new Array<PieceData | null>(size);
	
    if (mode === GameModeType.Infinite && board) {
        const density = getBoardDensity(board);
        let attempts = 0;
        
        while (attempts < 30) {
            const candidateHand: PieceData[] = [];
            for (let i = 0; i < size; i++) {
                if (density > 0.6 && Math.random() > 0.3) {
                    const smallPieces = piecesData.filter(p => {
                        let count = 0;
                        for(let row of p.matrix) for(let cell of row) if(cell === 1) count++;
                        return count <= 3;
                    });
                    const p = smallPieces[Math.floor(Math.random() * smallPieces.length)];
                    candidateHand.push({ ...p, color: getRandomPieceColorWorklet() });
                } else {
                    candidateHand.push(getRandomPieceWorklet());
                }
            }

            if (isHandIndestructible(board, candidateHand)) {
                for (let i = 0; i < size; i++) hand[i] = candidateHand[i];
                return hand;
            }
            attempts++;
        }
        
        // Final fallback
        for (let i = 0; i < size; i++) {
            hand[i] = getFittingPieceWorklet(board);
        }
    } else {
        for (let i = 0; i < size; i++) {
            hand[i] = getRandomPieceWorklet();
        }
    }
	return hand;
}

export function createRandomHandWorklet(size: number): Hand {
	"worklet";
	const hand = new Array<PieceData | null>(size);
	for (let i = 0; i < size; i++) {
		hand[i] = getRandomPieceWorklet();
	}
	return hand;
}