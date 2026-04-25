import React from 'react';
import { StyleSheet, Text, View, ScrollView } from 'react-native';
import SimplePopupView from './SimplePopupView';
import StylizedButton from './StylizedButton';
import { cssColors } from '@/constants/Color';
import { useSetAppState } from '@/hooks/useAppState';

export default function AboutMenu() {
    const [ _, __, popAppState ] = useSetAppState();

    return (
        <SimplePopupView style={{ justifyContent: 'flex-start', paddingVertical: 20 }}>
            <StylizedButton text="Back" onClick={popAppState} backgroundColor={cssColors.spaceGray} />
            
            <ScrollView style={styles.scroll} contentContainerStyle={styles.content}>
                <Text style={styles.header}>Welcome to Aether</Text>
                <Text style={styles.description}>
                    A strategic block-placing experience redesigned for precision, visual excellence, and infinite challenge.
                </Text>

                <View style={styles.modeSection}>
                    <Text style={[styles.modeTitle, { color: cssColors.green }]}>Infinite Mode</Text>
                    <Text style={styles.modeText}>
                        The ultimate strategic test. Our advanced backtracking engine ensures that every hand is "indestructible"—meaning there is always a valid path to survival.
                    </Text>
                    <Text style={styles.challenge}>
                        The Challenge: Try as hard as you can to fail. The engine works against your mistakes to keep you alive. Only the most reckless strategy can lead to a game over.
                    </Text>
                </View>

                <View style={styles.modeSection}>
                    <Text style={[styles.modeTitle, { color: cssColors.brightNiceRed }]}>Classic Mode</Text>
                    <Text style={styles.modeText}>
                        The traditional experience. Random pieces, no safety net. Manage your space wisely and aim for the highest score.
                    </Text>
                </View>

                <View style={styles.modeSection}>
                    <Text style={[styles.modeTitle, { color: 'yellow' }]}>Puzzle Mode</Text>
                    <Text style={styles.modeText}>
                        Structured challenges. Targeted blocks contain hidden gems. Collect the required amount of gems to progress to the next level.
                    </Text>
                </View>

                <Text style={styles.credits}>
                    built by peter thairu muigai aka thairux with love ❤️
                </Text>
                
                <Text style={styles.footer}>Master the grid. Control the Aether.</Text>
            </ScrollView>
        </SimplePopupView>
    );
}

const styles = StyleSheet.create({
    scroll: {
        width: '100%',
        marginTop: 10,
    },
    content: {
        paddingHorizontal: 20,
        paddingBottom: 40,
        alignItems: 'center'
    },
    header: {
        fontFamily: 'Silkscreen',
        fontSize: 28,
        color: 'white',
        textAlign: 'center',
        marginBottom: 15,
    },
    description: {
        fontFamily: 'Silkscreen',
        fontSize: 14,
        color: '#aaa',
        textAlign: 'center',
        marginBottom: 25,
        lineHeight: 20,
    },
    modeSection: {
        marginBottom: 25,
        borderLeftWidth: 3,
        borderLeftColor: 'rgba(255,255,255,0.1)',
        paddingLeft: 15,
        width: '100%'
    },
    modeTitle: {
        fontFamily: 'Silkscreen',
        fontSize: 20,
        marginBottom: 8,
    },
    modeText: {
        fontFamily: 'Silkscreen',
        fontSize: 12,
        color: '#eee',
        lineHeight: 18,
    },
    challenge: {
        fontFamily: 'Silkscreen',
        fontSize: 11,
        color: '#00ff00',
        marginTop: 8,
        fontStyle: 'italic',
    },
    credits: {
        fontFamily: 'Silkscreen',
        fontSize: 10,
        color: 'rgba(255, 255, 255, 0.4)',
        textAlign: 'center',
        marginTop: 10,
        marginBottom: 5,
        lineHeight: 16
    },
    footer: {
        fontFamily: 'Silkscreen',
        fontSize: 12,
        color: '#555',
        textAlign: 'center',
        marginTop: 5,
    }
});
