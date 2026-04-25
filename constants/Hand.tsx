import { PieceData, getRandomPiece, getRandomPieceWorklet, getFittingPieceWorklet } from "./Piece";
import { GameModeType } from "@/hooks/useAppState";

export type Hand = (PieceData | null)[]

export function createRandomHand(size: number): Hand {
	const hand = new Array<PieceData | null>(size);
	for (let i = 0; i < size; i++) {
		hand[i] = getRandomPiece();
	}
	return hand;
}

export function createHandWorklet(size: number, mode: GameModeType, board?: any): Hand {
	"worklet";
	const hand = new Array<PieceData | null>(size);
	for (let i = 0; i < size; i++) {
		if (mode === GameModeType.Infinite && board) {
			// At least one piece must fit in Infinite mode
			if (i === 0) {
				hand[i] = getFittingPieceWorklet(board);
			} else {
				hand[i] = getRandomPieceWorklet();
			}
		} else {
			hand[i] = getRandomPieceWorklet();
		}
	}
	// Shuffle hand if we forced a fitting piece at index 0
	if (mode === GameModeType.Infinite) {
		return hand.sort(() => Math.random() - 0.5);
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