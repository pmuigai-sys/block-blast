import { Board, BoardBlockType } from "./Board";
import { getRandomPieceColor } from "./Piece";

export interface Template {
    id: string;
    size: number;
    blocks: { x: number, y: number }[];
}

export const templates: Template[] = [
    {
        id: 'corner_4',
        size: 8,
        blocks: [
            { x: 0, y: 0 }, { x: 1, y: 0 },
            { x: 0, y: 1 }, { x: 1, y: 1 }
        ]
    },
    {
        id: 'center_cross',
        size: 8,
        blocks: [
            { x: 3, y: 3 }, { x: 4, y: 3 }, { x: 3, y: 4 }, { x: 4, y: 4 },
            { x: 2, y: 3 }, { x: 5, y: 3 }, { x: 3, y: 2 }, { x: 3, y: 5 }
        ]
    },
    {
        id: 'diagonal_line',
        size: 8,
        blocks: [
            { x: 0, y: 0 }, { x: 1, y: 1 }, { x: 2, y: 2 }, { x: 3, y: 3 }
        ]
    }
];

export function applyTemplate(board: Board, template: Template) {
    "worklet";
    for (const block of template.blocks) {
        if (block.x < board.length && block.y < board.length) {
            board[block.y][block.x].blockType = BoardBlockType.FILLED;
            board[block.y][block.x].color = getRandomPieceColor();
        }
    }
}

export function getRandomTemplate(size: number): Template | null {
    const possible = templates.filter(t => t.size === size);
    if (possible.length === 0) return null;
    return possible[Math.floor(Math.random() * possible.length)];
}
