import React, { useEffect, useRef } from 'react';
import { Audio } from 'expo-av';
import { useAppStateValue, MenuStateType } from '@/hooks/useAppState';

export default function AudioController() {
    const appState = useAppStateValue();
    const menuMusic = useRef<Audio.Sound | null>(null);
    const gameMusic = useRef<Audio.Sound | null>(null);

    useEffect(() => {
        async function setupAudio() {
            try {
                await Audio.setAudioModeAsync({
                    allowsRecordingIOS: false,
                    staysActiveInBackground: true,
                    playsInSilentModeIOS: true,
                    shouldDuckAndroid: true,
                    playThroughEarpieceAndroid: false,
                });

                const { sound: mSound } = await Audio.Sound.createAsync(
                    require('../assets/audio/music/menu_loop.wav'),
                    { isLooping: true, volume: 0.4 }
                );
                menuMusic.current = mSound;

                const { sound: gSound } = await Audio.Sound.createAsync(
                    require('../assets/audio/music/gameplay_loop.wav'),
                    { isLooping: true, volume: 0.35 }
                );
                gameMusic.current = gSound;

                updatePlayback(appState);
            } catch (e) {
                console.warn("Audio setup error", e);
            }
        }

        setupAudio();

        return () => {
            menuMusic.current?.unloadAsync();
            gameMusic.current?.unloadAsync();
        };
    }, []);

    useEffect(() => {
        updatePlayback(appState);
    }, [appState.current]);

    const updatePlayback = async (state: any) => {
        const isGame = state.containsGameMode();
        
        try {
            if (isGame) {
                if (menuMusic.current) await menuMusic.current.stopAsync();
                if (gameMusic.current) {
                    const status = await gameMusic.current.getStatusAsync();
                    if (status.isLoaded && !status.isPlaying) {
                        await gameMusic.current.playAsync();
                    }
                }
            } else {
                if (gameMusic.current) await gameMusic.current.stopAsync();
                if (menuMusic.current) {
                    const status = await menuMusic.current.getStatusAsync();
                    if (status.isLoaded && !status.isPlaying) {
                        await menuMusic.current.playAsync();
                    }
                }
            }
        } catch (e) {
            // Silently handle transition errors
        }
    };

    return null;
}

export const playVoiceReward = async (level: number) => {
    try {
        const voices = [
            require('../assets/audio/voice/nice.wav'),
            require('../assets/audio/voice/excellent.wav'),
            require('../assets/audio/voice/amazing.wav'),
            require('../assets/audio/voice/incredible.wav'),
            require('../assets/audio/voice/excellent.wav'), // fallback for higher
        ];
        
        const index = Math.min(level - 1, voices.length - 1);
        const { sound } = await Audio.Sound.createAsync(voices[index], { volume: 0.8 });
        await sound.playAsync();
        // Unload after playing to free memory
        sound.setOnPlaybackStatusUpdate((status) => {
            if (status.isLoaded && status.didJustFinish) {
                sound.unloadAsync();
            }
        });
    } catch (e) {
        console.warn("Voice reward error", e);
    }
};
