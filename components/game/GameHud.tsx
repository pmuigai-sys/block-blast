import { useEffect, useState } from "react"
import { Pressable, StyleSheet, Text, View } from "react-native"
import Animated, { SharedValue, interpolateColor, runOnJS, useAnimatedReaction, useAnimatedStyle, useSharedValue, withDelay, withSequence, withTiming } from "react-native-reanimated"
import { cssColors } from "@/constants/Color"
import { Hand } from "@/constants/Hand"
import { GameModeType, MenuStateType, useAppState, useSetAppState } from "@/hooks/useAppState"
import { getHighScores } from "@/constants/Storage"

interface ComboBarProps {
	lastBrokenLine: SharedValue<number>,
	handSize: number
}

function ComboBar({ lastBrokenLine, handSize }: ComboBarProps) {
	const totalBlocks = 10;
	const blockElements = [];

	for (let i = 0; i < totalBlocks; i++) {
		blockElements.push(<ComboBlock key={i} index={i} lastBrokenLine={lastBrokenLine} handSize={handSize}></ComboBlock>)
	}

	return <View style={styles.comboBarContainer}>
		{blockElements}
	</View>
}

function ComboBlock({ index, lastBrokenLine, handSize }: { index: number, lastBrokenLine: SharedValue<number>, handSize: number }) {
	const blockOpacity = useSharedValue(0);

	useAnimatedReaction(() => {
		return lastBrokenLine.value;
	}, (current, _prev) => {
		const targetOpacity = current == 0 ? 1 : 1 - (current / handSize);
		const baseIndex = index / 10;
		if (baseIndex < targetOpacity) {
			blockOpacity.value = withDelay(index * 20, withTiming(1, { duration: 100 }));
		} else {
			blockOpacity.value = withTiming(0, { duration: 100 });
		}
	})

	const animatedStyle = useAnimatedStyle(() => {
		return {
			opacity: blockOpacity.value,
			backgroundColor: interpolateColor(blockOpacity.value, [0, 1], ["rgba(255, 255, 255, 0.1)", "rgba(0, 255, 0, 1)"])
		}
	})

	return <Animated.View style={[styles.comboBlock, animatedStyle]}></Animated.View>
}

interface GameHudProps {
	score: SharedValue<number>,
	combo: SharedValue<number>,
	lastBrokenLine: SharedValue<number>,
	hand: SharedValue<Hand>,
	level?: SharedValue<number>,
	gems?: SharedValue<number>,
	gemsRequired?: SharedValue<number>,
	gameMode?: GameModeType
}

export function StatsGameHud({ score, combo, lastBrokenLine, hand, level, gems, gemsRequired, gameMode }: GameHudProps) {
	const [scoreText, setScoreText] = useState("0");
	const [levelText, setLevelText] = useState("1");
	const [gemsText, setGemsText] = useState("0/5");
	const scoreAnimValue = useSharedValue(0);

	useAnimatedReaction(() => {
		return score.value;
	}, (current, prev) => {
		scoreAnimValue.value = withTiming(current, { duration: 200 });
	})
	
	useAnimatedReaction(() => {
		return scoreAnimValue.value
	}, (current, _prev) => {
		runOnJS(setScoreText)(String(Math.floor(current)));
	})

	if (level) {
		useAnimatedReaction(() => level.value, (cur) => runOnJS(setLevelText)(String(cur)));
	}
	if (gems && gemsRequired) {
		useAnimatedReaction(() => [gems.value, gemsRequired.value], ([g, r]) => runOnJS(setGemsText)(`${g}/${r}`));
	}

	return <>
		<View style={styles.hudContainer}>
			<View style={styles.scoreContainer}>
				<Text style={{
					color: 'white',
					fontFamily: 'Silkscreen',
					fontSize: 50,
					fontWeight: '100',
					textShadowColor: 'rgb(0, 0, 0)',
					textShadowOffset: { width: 3, height: 3 },
					textShadowRadius: 10,
					alignSelf: 'center'
				}}>{scoreText}</Text>
			</View>
			{gameMode === GameModeType.Puzzle && (
				<View style={{flexDirection: 'row', justifyContent: 'space-around', width: '100%', marginBottom: 10}}>
					<Text style={{color: 'yellow', fontFamily: 'Silkscreen', fontSize: 20}}>Lvl {levelText}</Text>
					<Text style={{color: 'cyan', fontFamily: 'Silkscreen', fontSize: 20}}>💎 {gemsText}</Text>
				</View>
			)}
			<ComboBar lastBrokenLine={lastBrokenLine} handSize={hand.value.length}></ComboBar>
		</View>
	</>
}

export function StickyGameHud({gameMode, score}: {gameMode: GameModeType, score: SharedValue<number>}) {
	const [ highestScore, setHighestScore ] = useState(0);
	const [ scoreState, setScoreState ] = useState(score.value);

	useEffect(() => {
		getHighScores(gameMode, true, true, 1).then((highScores) => {
			if (highScores.length == 0) {
				setHighestScore(0);
				return;
			}
			setHighestScore(highScores[0].score);
		});
	}, [gameMode, setHighestScore]);
	
	useAnimatedReaction(() => {
		return score.value;
	}, (cur, prev) => {
		runOnJS(setScoreState)(cur);
	});

	return <View style={styles.stickyHudWrapper}>
		<View style={styles.highScoreContainer}>
			<Text style={styles.highScoreLabel}>{"👑" + Math.max(scoreState, highestScore)}</Text>
		</View>
		<SettingsButton></SettingsButton>
	</View>
}

function SettingsButton() {
	const [ _, appendAppState ] = useSetAppState();
	return <Pressable style={styles.settingsButton} onPress={() => {
		appendAppState(MenuStateType.OPTIONS);
	}}>
		<Text style={{ fontSize: 30 }}>⚙️</Text>
	</Pressable>
}

const styles = StyleSheet.create({
	hudContainer: {
		width: '100%',
		paddingHorizontal: 20,
		paddingTop: 80,
		alignItems: 'center',
		justifyContent: 'center',
		zIndex: 10,
	},
	scoreContainer: {
		marginBottom: 10,
	},
	comboBarContainer: {
		flexDirection: 'row',
		width: '80%',
		height: 10,
		backgroundColor: 'rgba(255,255,255,0.1)',
		borderRadius: 5,
		overflow: 'hidden',
	},
	comboBlock: {
		flex: 1,
		height: '100%',
		marginHorizontal: 1,
	},
	stickyHudWrapper: {
		position: 'absolute',
		top: 10,
		left: 0,
		right: 0,
		height: 60,
		flexDirection: 'row',
		justifyContent: 'space-between',
		alignItems: 'center',
		paddingHorizontal: 20,
		zIndex: 1000,
	},
	highScoreContainer: {
		backgroundColor: 'rgba(0,0,0,0.5)',
		paddingHorizontal: 15,
		paddingVertical: 8,
		borderRadius: 20,
		borderWidth: 1,
		borderColor: 'rgba(255,255,255,0.2)',
	},
	highScoreLabel: {
		color: 'white',
		fontFamily: 'Silkscreen',
		fontSize: 18,
	},
	settingsButton: {
		width: 50,
		height: 50,
		justifyContent: 'center',
		alignItems: 'center',
	},
})
