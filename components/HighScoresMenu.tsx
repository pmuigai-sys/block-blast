import { getHighScores, HighScore } from "@/constants/Storage";
import SimplePopupView from "./SimplePopupView";
import { useEffect, useState } from "react";
import { StyleSheet, Text, View, ScrollView } from "react-native";
import StylizedButton from "./StylizedButton";
import { cssColors } from "@/constants/Color";
import { GameModeType, useSetAppState } from "@/hooks/useAppState";

export default function HighScores() {
    const [ setAppState, _appendAppState, popAppState ] = useSetAppState();
    const [ highScores, setHighScores ] = useState<HighScore[]>([]);
    const [ gameMode, setGameMode ] = useState(GameModeType.Infinite);
    
    useEffect(() => {
        getHighScores(gameMode, true, true, 10).then((value) => {
            setHighScores(value);
        });
    }, [gameMode, setHighScores]);

    const renderModeButtons = () => (
        <View style={{flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 5, marginBottom: 10}}>
            <StylizedButton text="Infinite" onClick={() => { setGameMode(GameModeType.Infinite) }} backgroundColor={cssColors.green} style={{width: 120}}></StylizedButton>
            <StylizedButton text="Classic" onClick={() => { setGameMode(GameModeType.Classic) }} backgroundColor={cssColors.brightNiceRed} style={{width: 120}}></StylizedButton>
            <StylizedButton text="Puzzle" onClick={() => { setGameMode(GameModeType.Puzzle) }} backgroundColor={cssColors.pitchBlack} style={{width: 120}} borderColor="white"></StylizedButton>
        </View>
    );

    return <SimplePopupView style={[{justifyContent: 'flex-start'}]}>
        <StylizedButton text="Back" onClick={popAppState} backgroundColor={cssColors.spaceGray}></StylizedButton>
        
        <Text style={styles.subHeader}>
            {"Select a game mode..."}
        </Text>
        
        {renderModeButtons()}

        { highScores.length > 0 &&
            <ScrollView style={{width: '100%'}} contentContainerStyle={{alignItems: 'center'}}>
                <Text style={styles.header}>
                    {`${gameMode.toUpperCase()} top 10`}
                </Text>
                {
                    highScores.map((score, idx) => {
                        return <Score key={idx} rank={idx + 1} score={score}/>
                    })
                }
            </ScrollView>
        }
        { highScores.length == 0 && 
            <View style={{alignItems: 'center'}}>
                <Text style={styles.noScoresText}>{"No scores yet for this mode!"}</Text>
                <StylizedButton text={`Play ${gameMode}`} onClick={() => {
                    setAppState(gameMode)
                }} backgroundColor={cssColors.brightNiceRed}></StylizedButton>
            </View>
        }
    </SimplePopupView>
}

function Score({score, rank}: {score: HighScore, rank: number}) {
    return <View style={{marginBottom: 10, alignItems: 'center'}}>
        <Text style={styles.scoreValueText}>{"#" + String(rank) + " - " + String(score.score)}</Text>
        <Text style={styles.scoreTimeText}>{createTimeAgoString(score.date)}</Text>
    </View>
}

function createTimeAgoString(date: number): string {
    const now = new Date();
    const seconds = Math.round((now.getTime() - date) / 1000);
    const minutes = Math.round(seconds / 60);
    const hours = Math.round(minutes / 60);
    const days = Math.round(hours / 24);
    const months = Math.round(days / 30);
    const years = Math.round(days / 365);
  
    if (seconds < 60) {
      return seconds <= 0 ? 'now' : `${seconds} seconds ago`;
    } else if (minutes < 60) {
      return `${minutes} minutes ago`;
    } else if (hours < 24) {
      return `${hours} hours ago`;
    } else if (days < 30) {
      return `${days} days ago`;
    } else if (months < 12) {
      return `${months} months ago`;
    } else {
      return `${years} years ago`;
    }
  }

const styles = StyleSheet.create({
    noScoresText: {
        color: 'white',
        fontSize: 24,
        fontFamily: 'Silkscreen',
        textAlign: 'center',
        marginBottom: 20
    },
    scoreValueText: {
        color: 'white',
        fontSize: 24,
        fontFamily: 'Silkscreen'
    },
    scoreTimeText: {
        color: 'rgb(150, 150, 150)',
        fontSize: 12,
        fontFamily: 'Silkscreen'
    },
    header: {
        color: 'white',
        fontSize: 28,
        fontFamily: 'Silkscreen',
        marginBottom: 10
    },
    subHeader: {
        color: 'rgb(100, 100, 100)',
        fontSize: 18,
        fontFamily: 'Silkscreen',
        marginBottom: 10
    }
});