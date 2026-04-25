import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Color, colorToHex, lighten, darken } from '@/constants/Color';

interface BlockVisualProps {
    color: Color;
    size: number;
    opacity?: number;
    isGhost?: boolean;
}

export default function BlockVisual({ color, size, opacity = 1, isGhost = false }: BlockVisualProps) {
    const baseColor = colorToHex(color);
    const light = colorToHex(lighten(color, 0.4));
    const lighter = colorToHex(lighten(color, 0.6));
    const dark = colorToHex(darken(color, 0.3));
    const darker = colorToHex(darken(color, 0.5));

    const b = size * 0.22; // bevel size

    return (
        <View style={[styles.container, { width: size, height: size, opacity: isGhost ? 0.3 : opacity }]}>
            {/* Dark base layer */}
            <View style={[StyleSheet.absoluteFill, { backgroundColor: darker }]} />

            {/* Top Bevel - lighter highlights */}
            <View style={[styles.bevel, {
                borderBottomWidth: b,
                borderBottomColor: lighter,
                borderLeftWidth: b,
                borderLeftColor: 'transparent',
                borderRightWidth: b,
                borderRightColor: 'transparent',
                top: 0, left: 0, right: 0,
            }]} />

            {/* Bottom Bevel - darker shadows */}
            <View style={[styles.bevel, {
                borderTopWidth: b,
                borderTopColor: darker,
                borderLeftWidth: b,
                borderLeftColor: 'transparent',
                borderRightWidth: b,
                borderRightColor: 'transparent',
                bottom: 0, left: 0, right: 0,
            }]} />

            {/* Left Bevel */}
            <View style={[styles.bevel, {
                borderRightWidth: b,
                borderRightColor: light,
                borderTopWidth: b,
                borderTopColor: 'transparent',
                borderBottomWidth: b,
                borderBottomColor: 'transparent',
                left: 0, top: 0, bottom: 0,
            }]} />

            {/* Right Bevel */}
            <View style={[styles.bevel, {
                borderLeftWidth: b,
                borderLeftColor: dark,
                borderTopWidth: b,
                borderTopColor: 'transparent',
                borderBottomWidth: b,
                borderBottomColor: 'transparent',
                right: 0, top: 0, bottom: 0,
            }]} />

            {/* Inner Flat Face with subtle indentation line */}
            <View style={{
                position: 'absolute',
                top: b, left: b, right: b, bottom: b,
                backgroundColor: baseColor,
                borderWidth: 1,
                borderColor: 'rgba(0,0,0,0.2)'
            }}>
                 {/* Subtle inner indentation to match screenshot exactly */}
                 <View style={{
                     position: 'absolute',
                     top: 2, left: 2, right: 2, bottom: 2,
                     borderWidth: 1,
                     borderColor: 'rgba(255,255,255,0.1)',
                 }} />
            </View>

            {/* Outer crisp black border for block separation */}
            <View style={styles.outerBorder} />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        position: 'relative',
        overflow: 'hidden',
    },
    bevel: {
        position: 'absolute',
        width: '100%',
        height: '100%',
    },
    outerBorder: {
        ...StyleSheet.absoluteFillObject,
        borderWidth: 1.5,
        borderColor: 'black',
    }
});
