import { useAtom, useSetAtom } from "jotai";
import { useEffect } from "react";
import { Pressable, StyleSheet, Text, View, ViewStyle, ScrollView, Platform, Linking } from "react-native";
import Animated, { BounceInUp, Easing, FadeIn, interpolateColor, useAnimatedStyle, useDerivedValue, useSharedValue, withDelay, withRepeat, withSequence, withSpring, withTiming } from "react-native-reanimated";
import { MenuStateType, useSetAppState } from "@/hooks/useAppState";
import { cssColors } from "@/constants/Color";
import { GameModeType } from '@/hooks/useAppState';
import HighScores from "./HighScoresMenu";
import { PieceData } from "@/constants/Piece";
import { PieceView } from "./PieceView";
import AboutMenu from "./AboutMenu";

// Celestial 'A' logo for Aether
const logoAPiece: PieceData = {
	matrix: [
		[0, 1, 1, 0],
		[1, 0, 0, 1],
		[1, 1, 1, 1],
		[1, 0, 0, 1],
		[1, 0, 0, 1]
	],
	distributionPoints: 0,
	color: { r: 100, g: 200, b: 255 } // Ethereal Blue
};

const logoSPiece: PieceData = {
	matrix: [
		[1, 1, 1, 1],
		[0, 0, 1, 0],
		[0, 1, 0, 0],
		[1, 1, 1, 1]
	],
	distributionPoints: 0,
	color: { r: 200, g: 100, b: 255 } // Aether Purple
};

function AetherLogo({blockSize, style}: {blockSize: number, style: ViewStyle}) {
	const nTop = blockSize * 60/30
	const nLeft = blockSize * 40/30
	return <View style={[{width: blockSize * 4 + nLeft, height: blockSize * 5 + nTop}, style]}>
		<PieceView style={{boxShadow: '0px 0px 40px rgba(100, 200, 255, 0.4)', backgroundColor: 'rgba(0, 0, 0, 0.4)'}} piece={logoAPiece} blockSize={blockSize}></PieceView>
		<PieceView style={{transform: [{ translateX: nLeft }, { translateY: nTop }], position: 'absolute', zIndex: -1}} piece={logoSPiece} blockSize={blockSize}></PieceView>
	</View>
}

export default function MainMenu() {
	const [ appState, appendAppState ] = useSetAppState();
	
	if (appState.current === MenuStateType.ABOUT) {
		return <AboutMenu />;
	}

	return <View style={styles.container}>

		<AetherLogo style={{position: 'absolute', bottom: 20, left: 20}} blockSize={6}></AetherLogo>
		<View style={{ alignItems: 'center', marginBottom: 40 }}>
            <Animated.Text entering={BounceInUp.duration(800)} style={[styles.logo]}>
                aether
            </Animated.Text>
            <Animated.Text entering={FadeIn.delay(600)} style={styles.subtitle}>
                by thairux
            </Animated.Text>
        </View>

		<MainButton
			onClick={() => {
				appendAppState(GameModeType.Infinite);
			}}
			backgroundColor={cssColors.green}
			title={"Infinite"}
			flavorText={"indestructible survival"}
			idleBounce={true}
		/>
		<MainButton
			onClick={() => {
				appendAppState(GameModeType.Classic);
			}}
			backgroundColor={cssColors.brightNiceRed}
			title={"Classic"}
			flavorText={"random pieces challenge"}
		/>
		<MainButton
			onClick={() => {
				appendAppState(GameModeType.Puzzle);
			}}
			backgroundColor={cssColors.pitchBlack}
			title={"Puzzle"}
			flavorText={"collect gems to level up"}
			style={{ borderWidth: 2, borderColor: "rgb(50, 50, 50)" }}
			textStyle={{ color: "white" }}
			idleBounceRotate={true}
		/>

        {Platform.OS === 'web' && (
            <MainButton 
                onClick={() => Linking.openURL('https://github.com/Thairux/block-blast/releases/latest')}
                backgroundColor={"#222"}
                title={"Download APK"}
                flavorText={"get aether for android"}
                style={{borderColor: '#444', height: 50}}
                textStyle={{color: '#999', fontSize: 18}}
            />
        )}
		
        <View style={{flexDirection: 'row', width: '80%', gap: 10, maxWidth: 420, marginTop: 10}}>
            <MainButton onClick = {() => {
                appendAppState(MenuStateType.HIGH_SCORES)
            }} backgroundColor={cssColors.pink} title={"Scores"} style={{flex: 1}} />
            <MainButton onClick = {() => {
                appendAppState(MenuStateType.ABOUT)
            }} backgroundColor={cssColors.spaceGray} title={"About"} style={{flex: 1}} />
        </View>

		<Animated.Text entering={FadeIn} style={styles.footer}>
			v2.0 - celestial edition
		</Animated.Text>
	</View>
}

function MainButton({
	style,
	textStyle,
	backgroundColor,
	title,
	flavorText,
	idleBounce,
	idleBounceRotate,
	onClick,
}: {
	style?: any;
	textStyle?: any;
	backgroundColor: string;
	title: string;
	flavorText?: string;
	idleBounce?: boolean;
	idleBounceRotate?: boolean;
	onClick?: () => void;
}) {
	const scale = useSharedValue(1);
	const idleAnimTranslateY = useSharedValue(0);
	const hoverAnimTranslateY = useSharedValue(0);
	const translateY = useDerivedValue(() => {
		return idleAnimTranslateY.value + hoverAnimTranslateY.value; 
	});
	const rotationDeg = useSharedValue(0);

	const animatedStyle = useAnimatedStyle(() => {
		return {
			transform: [
				{ translateY: translateY.value },
				{ rotate: `${rotationDeg.value}deg` },
				{ scale: scale.value }
			]
		};
	});

	useEffect(() => {
		const idleBounceTotalTime = 3700;
		if (idleBounce) {
			idleAnimTranslateY.value = withRepeat(
				withSequence(
					withDelay(2500, withTiming(-30, { duration: 200 })),
					withTiming(0, { duration: 1000, easing: Easing.bounce }),
				),
				1000,
			);
		} else if (idleBounceRotate) {
			const amplitude = 10;
			const steps = 5;
			const stepDuration = 160;
			const anims = [];
			for (let i = 0; i < steps; i++) {
				let deg;
				if (i == steps - 1) {
					deg = 0;
				} else {
					deg = i % 2 == 0 ? -amplitude : amplitude;
				}
				anims.push(
					withTiming(deg, { duration: stepDuration, easing: Easing.cubic }),
				);
			}

			rotationDeg.value = withRepeat(
				withDelay(
					idleBounceTotalTime - stepDuration * steps,
					withSequence(...anims),
				),
				1000,
			);
		}
	}, []);

	const onPress = () => {
		scale.value = withSequence(withTiming(1.25, { duration: 200 }), withTiming(1, { duration: 200 }));
		if (onClick)
			onClick();
	}
	
	const onHoverIn = () => {
		hoverAnimTranslateY.value = withSpring(-10, {duration: 400});
	}
	
	const onHoverOut = () => {
		hoverAnimTranslateY.value = withSpring(0, {duration: 400});
	}
	
	return (
		<Pressable style={[styles.buttonPressable, style]} onPress={onPress} onHoverIn={onHoverIn} onHoverOut={onHoverOut}>
			<Animated.View
				key={title}
				style={[
					styles.button,
					{ backgroundColor },
					animatedStyle,
				]}
			>
				<Text style={[styles.buttonText, textStyle ? textStyle : {}]}>
					{title}
				</Text>
				{flavorText && (
					<Text style={[styles.buttonFlavorText, textStyle ? textStyle : {}]}>
						{flavorText}
					</Text>
				)}
			</Animated.View>
		</Pressable>
	);
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		alignItems: "center",
		justifyContent: "center",
		width: '100%',
		height: '100%'
	},
	logo: {
		fontFamily: "Silkscreen",
		fontSize: 50,
		color: "#FFF",
		textAlign: "center",
		textShadowColor: 'rgba(100, 200, 255, 0.8)',
		textShadowOffset: { width: 0, height: 0 },
		textShadowRadius: 20
	},
    subtitle: {
        fontFamily: "Silkscreen",
        fontSize: 16,
        color: "rgba(255, 255, 255, 0.6)",
        textAlign: "center",
        marginTop: -5
    },
	button: {
		width: "100%",
		height: "100%",
		justifyContent: "center",
		alignItems: "center",
		borderRadius: 8,
		borderWidth: 2,
        borderColor: 'black'
	},
	buttonPressable: {
		width: "80%",
		height: 65,
		justifyContent: "center",
		alignItems: "center",
		marginBottom: 15,
		borderRadius: 10,
		maxWidth: 420
	},
	buttonText: {
		fontFamily: "Silkscreen",
		fontSize: 24,
		color: "black",
		textAlign: 'center'
	},
	buttonFlavorText: {
		fontFamily: "Silkscreen",
		fontSize: 12,
		color: "rgb(30, 30, 30)",
		textAlign: 'center',
        opacity: 0.7
	},
	footer: {
		fontFamily: "Silkscreen",
		fontSize: 14,
		color: "#777",
		position: "absolute",
		bottom: 20,
	},
});