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
			// All pieces must fit independently in Infinite mode
			hand[i] = getFittingPieceWorklet(board);
		} else {
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