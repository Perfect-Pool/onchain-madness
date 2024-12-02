import { ActionFn, Context, Event } from "@tenderly/actions";

import { ethers } from "ethers";
import axios from "axios";

type Game = {
    id: string;
    status: string;
    title: string;
    home_points: number;
    away_points: number;
    home: {
        alias: string;
    };
    away: {
        alias: string;
    };
};

type Region = {
    teams: string[];
    scores: number[];
};

type RegionData = {
    teams: string[];
    matchesRound1: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    }[];
    matchesRound2: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    }[];
    matchesRound3: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    }[];
    matchRound4: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    };
    winner: string;
};

type RoundsData = {
    south: RegionData;
    west: RegionData;
    midwest: RegionData;
    east: RegionData;
};

type FirstFour = {
    matches: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    }[];
}

type FinalFour = {
    round1: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    }[];
    final: {
        home: string;
        away: string;
        home_points: number;
        away_points: number;
        winner: string;
    };
    winner: string;
};

type FinalMatch = {
    home: string;
    away: string;
    home_points: number;
    away_points: number;
}

type TournamentRegions = {
    south: Region;
    west: Region;
    midwest: Region;
    east: Region;
};

function processGames(length: number, games: Game[]): Region {
    let teams: string[] = [];
    let scores: number[] = [];
    let gamesOrdered: Game[] = games.sort((a, b) => {
        const gameNumber = parseInt(a.title.split(" - Game ")[1]);
        return gameNumber - parseInt(b.title.split(" - Game ")[1]);
    });


    // Itera pelos jogos ordenados e constrói os arrays de retorno
    gamesOrdered.forEach((game) => {
        const homeTeam = game?.home?.alias || "";
        const awayTeam = game?.away?.alias || "";

        const homePoints = game.status === "closed" ? (game?.home_points || 0) : 0;
        const awayPoints = game.status === "closed" ? (game?.away_points || 0) : 0;

        teams.push(homeTeam);
        teams.push(awayTeam);
        scores.push(homePoints);
        scores.push(awayPoints);
    });

    return { teams, scores };
}

const getMmInfo = async (
    madnessData: any,
    round: number,
    context: Context
): Promise<TournamentRegions> => {
    const sequence = round + 1;
    const length = round === 1 ? 16 : round === 2 ? 8 : round === 3 ? 4 : 2;

    try {
        let roundData: any;
        madnessData.rounds.forEach((r: any) => {
            if (r.sequence === sequence) {
                roundData = r;
            }
        });

        if (roundData === undefined) {
            throw new Error("Round data not found");
        }

        let southRegion: Region = { teams: [], scores: [] };
        let westRegion: Region = { teams: [], scores: [] };
        let midwestRegion: Region = { teams: [], scores: [] };
        let eastRegion: Region = { teams: [], scores: [] };

        roundData.bracketed.forEach((r: any) => {
            if (r.bracket.name === "South Regional") {
                southRegion = processGames(length, r.games);
            } else if (r.bracket.name === "West Regional") {
                westRegion = processGames(length, r.games);
            } else if (r.bracket.name === "Midwest Regional") {
                midwestRegion = processGames(length, r.games);
            } else if (r.bracket.name === "East Regional") {
                eastRegion = processGames(length, r.games);
            } else {
                console.log("Bracket not found:", r.bracket.name);
            }
        });

        return {
            south: southRegion,
            west: westRegion,
            midwest: midwestRegion,
            east: eastRegion,
        };
    } catch (error) {
        console.error("Sportradar API call failed:", error);
        return {
            south: { teams: [], scores: [] },
            west: { teams: [], scores: [] },
            midwest: { teams: [], scores: [] },
            east: { teams: [], scores: [] },
        };
    }
};

const getFirstFour = async (madnessData: any, context: Context): Promise<Region> => {
    const sequence = 1;
    const length = 4;

    try {
        let roundData: any;
        madnessData.rounds.forEach((r: any) => {
            if (r.sequence === sequence) {
                roundData = r;
            }
        });

        if (roundData === undefined) {
            throw new Error("Round data not found");
        }

        let firstFour: Region = { teams: [], scores: [] };

        roundData.bracketed.forEach((r: any) => {
            const getGames = processGames(length, r.games);
            firstFour.teams = firstFour.teams.concat(getGames.teams);
            firstFour.scores = firstFour.scores.concat(getGames.scores);
        });

        // remove empty strings from the array, get the indexes of the empty strings and remove the corresponding scores
        let newFirstFour: Region = { teams: [], scores: [] };
        firstFour.teams.forEach((team, index) => {
            if (team !== "") {
                newFirstFour.teams.push(team);
                newFirstFour.scores.push(firstFour.scores[index]);
            }
        });

        return newFirstFour;
    } catch (error) {
        console.error("Sportradar API call failed:", error);
        return { teams: [], scores: [] };
    }
}

const getFirstGame = async (madnessData: any, context: Context): Promise<Date> => {

    try {
        let roundData: any;
        madnessData.rounds.forEach((r: any) => {
            if (r.sequence === 2) {
                roundData = r;
            }
        });

        if (roundData === undefined) {
            throw new Error("Round data not found");
        }

        let firstRoundStartDate = new Date("2050-12-31T23:59:59Z");

        roundData.bracketed.forEach((r: any) => {
            r.games.forEach((game: any) => {
                const gameDate = new Date(game.scheduled);
                if (gameDate < firstRoundStartDate) {
                    firstRoundStartDate = gameDate;
                }
            });
        });

        return firstRoundStartDate;
    } catch (error) {
        console.error("Sportradar API call failed:", error);
        return new Date("2050-12-31T23:59:59Z");
    }
}

const getFinalFour = async (madnessData: any, context: Context): Promise<Region> => {
    const sequence = 6;

    try {
        let roundData: any;
        madnessData.rounds.forEach((r: any) => {
            if (r.sequence === sequence) {
                roundData = r;
            }
        });

        if (roundData === undefined) {
            throw new Error("Round data not found");
        }

        const game1 = roundData.games[0].title.indexOf("Game 1") !== -1 ? roundData.games[0] : roundData.games[1];
        const game2 = roundData.games[1].title.indexOf("Game 2") !== -1 ? roundData.games[1] : roundData.games[0];
        let finalFour: Region = {
            teams: [game1.home.alias, game1.away.alias, game2.home.alias, game2.away.alias],
            scores: [game1.home_points, game1.away_points, game2.home_points, game2.away_points]
        };

        return finalFour;
    } catch (error) {
        console.error("Sportradar API call failed:", error);
        return {
            teams: [],
            scores: []
        };
    }
}

const getFinalMatch = async (madnessData: any, context: Context): Promise<FinalMatch> => {
    const sequence = 7;

    try {
        let roundData: any;
        madnessData.rounds.forEach((r: any) => {
            if (r.sequence === sequence) {
                roundData = r;
            }
        });

        if (roundData === undefined) {
            throw new Error("Round data not found");
        }

        const game = roundData.games[0];
        let finalMatch: FinalMatch = {
            home: game.home.alias,
            away: game.away.alias,
            home_points: game.home_points,
            away_points: game.away_points,
        };

        return finalMatch;
    } catch (error) {
        console.error("Sportradar API call failed:", error);
        return {
            home: "",
            away: "",
            home_points: 0,
            away_points: 0,
        };
    }
}


// const getGasPrice = async (
//     baseScanUrl: string,
//     baseScanKey: string
// ): Promise<ethers.BigNumber> => {
//     try {
//         const response = await axios.get(
//             `${baseScanUrl}?module=proxy&action=eth_gasPrice&apikey=${baseScanKey}`
//         );
//         const proposedGasPriceHex = response.data.result;
//         const gasPriceGwei = ethers.BigNumber.from(proposedGasPriceHex);

//         // Increase the gas price by 10%
//         const increasedGasPrice = gasPriceGwei.mul(110).div(100);
//         return increasedGasPrice;
//     } catch (error) {
//         console.log("Failed to fetch gas price:", error);
//         return ethers.utils.parseUnits("10", "gwei");
//     }
// };

async function getGasPrice(provider: ethers.providers.Provider): Promise<ethers.BigNumber> {
    try {
        const gasPrice = await provider.getGasPrice();
        return gasPrice;
    } catch (error) {
        console.error("Erro ao obter o preço do GAS:", error);
        throw error;
    }
}

const createNewTournament = async (
    madnessData: any,
    marchMadness: any,
    GAME_YEAR: number,
    gasPrice: ethers.BigNumber,
    context: Context
): Promise<string> => {
    const firstFour = await getFirstFour(madnessData, context);
    const regions = await getMmInfo(madnessData, 1, context);
    if (
        firstFour.teams.length === 0 ||
        regions.south.teams.length === 0 ||
        regions.west.teams.length === 0 ||
        regions.midwest.teams.length === 0 ||
        regions.east.teams.length === 0
    ) {
        console.error("Failed to fetch March Madness data");
        return "";
    }
    console.log("Creating new March Madness contract, year:", GAME_YEAR);
    console.log("First Four:", firstFour.teams);
    console.log("South Region:", regions.south.teams);
    console.log("West Region:", regions.west.teams);
    console.log("Midwest Region:", regions.midwest.teams);
    console.log("East Region:", regions.east.teams);

    try {
        const estimatedGas = await marchMadness.estimateGas.createMarchMadness(
            GAME_YEAR,
            firstFour.teams,
            regions.south.teams,
            regions.west.teams,
            regions.midwest.teams,
            regions.east.teams
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.createMarchMadness(
            GAME_YEAR,
            firstFour.teams,
            regions.south.teams,
            regions.west.teams,
            regions.midwest.teams,
            regions.east.teams,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`New March Madness contract created. TX: ${tx.hash}`);
        const tournamentContract = await marchMadness.tournaments(GAME_YEAR);
        return tournamentContract;
    } catch (error) {
        console.error("Failed to create March Madness contract:", error);
        return "";
    }
};

const determineFirstFourWinners = async (
    marchMadness: any,
    GAME_YEAR: number,
    firstFour: Region,
    gasPrice: ethers.BigNumber
): Promise<void> => {
    let winners: string[] = [];
    console.log("Teams:", firstFour.teams);
    for (let i = 0; i < firstFour.teams.length; i += 2) {
        if (firstFour.scores[i] > firstFour.scores[i + 1]) {
            winners.push(firstFour.teams[i]);
        } else if (firstFour.scores[i] < firstFour.scores[i + 1]) {
            winners.push(firstFour.teams[i + 1]);
        } else {
            winners.push("");
        }
    }
    console.log("Winners:", winners);

    try {
        const estimatedGas = await marchMadness.estimateGas.determineFirstFourWinners(
            GAME_YEAR,
            firstFour.teams,
            firstFour.scores,
            winners
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineFirstFourWinners(
            GAME_YEAR,
            firstFour.teams,
            firstFour.scores,
            winners,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`First Four Winners updated. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine First Four Winners:", error);
    }
}

const determineRound1Winners = async (
    marchMadness: any,
    GAME_YEAR: number,
    regionName: string,
    teamNames: string[],
    scores: number[],
    gasPrice: ethers.BigNumber
): Promise<void> => {
    let winners: string[] = [];
    for (let i = 0; i < teamNames.length; i += 2) {
        if (scores[i] > scores[i + 1]) {
            winners.push(teamNames[i]);
        } else if (scores[i] < scores[i + 1]) {
            winners.push(teamNames[i + 1]);
        } else {
            winners.push("");
        }
    }
    try {
        const estimatedGas = await marchMadness.estimateGas.determineRound1Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineRound1Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Round 1 Winners updated for ${regionName}. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Round 1 Winners:", error);
    }
}

const determineRound2Winners = async (
    marchMadness: any,
    GAME_YEAR: number,
    regionName: string,
    teamNames: string[],
    scores: number[],
    gasPrice: ethers.BigNumber
): Promise<void> => {
    let winners: string[] = [];
    for (let i = 0; i < teamNames.length; i += 2) {
        if (scores[i] > scores[i + 1]) {
            winners.push(teamNames[i]);
        } else if (scores[i] < scores[i + 1]) {
            winners.push(teamNames[i + 1]);
        } else {
            winners.push("");
        }
    }
    try {
        const estimatedGas = await marchMadness.estimateGas.determineRound2Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineRound2Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Round 2 Winners updated for ${regionName}. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Round 2 Winners:", error);
    }
}


const determineRound3Winners = async (
    marchMadness: any,
    GAME_YEAR: number,
    regionName: string,
    teamNames: string[],
    scores: number[],
    gasPrice: ethers.BigNumber
): Promise<void> => {
    let winners: string[] = [];
    for (let i = 0; i < teamNames.length; i += 2) {
        if (scores[i] > scores[i + 1]) {
            winners.push(teamNames[i]);
        } else if (scores[i] < scores[i + 1]) {
            winners.push(teamNames[i + 1]);
        } else {
            winners.push("");
        }
    }
    try {
        const estimatedGas = await marchMadness.estimateGas.determineRound3Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineRound3Winners(
            GAME_YEAR,
            regionName,
            teamNames,
            scores,
            winners,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Round 3 Winners updated for ${regionName}. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Round 3 Winners:", error);
    }
}

const determineRound4Winners = async (
    marchMadness: any,
    GAME_YEAR: number,
    regionName: string,
    teamNameHome: string,
    teamNameAway: string,
    scoreHome: number,
    scoreAway: number,
    gasPrice: ethers.BigNumber
): Promise<void> => {
    const winner = scoreHome === scoreAway ? "" : scoreHome > scoreAway ? teamNameHome : teamNameAway;
    try {
        const estimatedGas = await marchMadness.estimateGas.determineRound4Winners(
            GAME_YEAR,
            regionName,
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineRound4Winners(
            GAME_YEAR,
            regionName,
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Round 4 Winners updated for ${regionName}. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Round 4 Winners:", error);
    }
}

const determineFinalFourWinners = async (
    marchMadness: any,
    GAME_YEAR: number,
    teamNames: string[],
    scores: number[],
    gasPrice: ethers.BigNumber
): Promise<void> => {
    let winners: string[] = [];
    for (let i = 0; i < teamNames.length; i += 2) {
        if (scores[i] > scores[i + 1]) {
            winners.push(teamNames[i]);
        } else if (scores[i] < scores[i + 1]) {
            winners.push(teamNames[i + 1]);
        } else {
            winners.push("");
        }
    }
    try {
        const estimatedGas = await marchMadness.estimateGas.determineFinalFourWinners(
            GAME_YEAR,
            teamNames,
            scores,
            winners
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineFinalFourWinners(
            GAME_YEAR,
            teamNames,
            scores,
            winners,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Final Four Winners updated. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Final Four Winners:", error);
    }
}

const determineChampion = async (
    marchMadness: any,
    GAME_YEAR: number,
    teamNameHome: string,
    teamNameAway: string,
    scoreHome: number,
    scoreAway: number,
    gasPrice: ethers.BigNumber
): Promise<void> => {
    const winner = scoreHome === scoreAway ? "" : scoreHome > scoreAway ? teamNameHome : teamNameAway;
    try {
        const estimatedGas = await marchMadness.estimateGas.determineChampion(
            GAME_YEAR,
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner
        );
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.determineChampion(
            GAME_YEAR,
            teamNameHome,
            teamNameAway,
            scoreHome,
            scoreAway,
            winner,
            {
                gasLimit: gasLimit,
                gasPrice: gasPrice,
            }
        );

        await tx.wait(1);
        console.log(`Champion determined. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to determine Champion:", error);
    }
}

const getFirstFourDataDecoded = async (
    marchMadness: any,
    GAME_YEAR: number
): Promise<FirstFour> => {
    const getFirstFourData = await marchMadness.getFirstFourData(GAME_YEAR);

    const matchesDecoded = getFirstFourData.map((match: any) => {
        const [home, away, home_points, away_points, winner] =
            ethers.utils.defaultAbiCoder.decode(
                ["string", "string", "uint256", "uint256", "string"],
                match
            );
        return { home, away, home_points, away_points, winner };
    });

    return { matches: matchesDecoded };
}

const getRegionDataDecoded = async (
    regionData: any
): Promise<RegionData> => {
    const regionDataDecoded =
        ethers.utils.defaultAbiCoder.decode(
            ["string[16]", "bytes[8]", "bytes[4]", "bytes[2]", "bytes", "string"],
            regionData
        );

    const teams = regionDataDecoded[0];
    const matchesRound1 = regionDataDecoded[1];
    const matchesRound2 = regionDataDecoded[2];
    const matchesRound3 = regionDataDecoded[3];
    const matchRound4 = regionDataDecoded[4];
    const winner = regionDataDecoded[5];

    const round1Decoded = matchesRound1.map((match: any) => {
        const matchDecoded =
            ethers.utils.defaultAbiCoder.decode(
                ["string", "string", "uint256", "uint256", "string"],
                match
            );
        return {
            home: matchDecoded[0],
            away: matchDecoded[1],
            home_points: matchDecoded[2],
            away_points: matchDecoded[3],
            winner: matchDecoded[4]
        };
    });

    const round2Decoded = matchesRound2.map((match: any) => {
        const matchDecoded =
            ethers.utils.defaultAbiCoder.decode(
                ["string", "string", "uint256", "uint256", "string"],
                match
            );
        return {
            home: matchDecoded[0],
            away: matchDecoded[1],
            home_points: matchDecoded[2],
            away_points: matchDecoded[3],
            winner: matchDecoded[4]
        };
    });

    const round3Decoded = matchesRound3.map((match: any) => {
        const matchDecoded =
            ethers.utils.defaultAbiCoder.decode(
                ["string", "string", "uint256", "uint256", "string"],
                match
            );
        return {
            home: matchDecoded[0],
            away: matchDecoded[1],
            home_points: matchDecoded[2],
            away_points: matchDecoded[3],
            winner: matchDecoded[4]
        };
    });

    const matchRound4Decoded = ethers.utils.defaultAbiCoder.decode(
        ["string", "string", "uint256", "uint256", "string"],
        matchRound4
    );

    return {
        teams,
        matchesRound1: round1Decoded,
        matchesRound2: round2Decoded,
        matchesRound3: round3Decoded,
        matchRound4: {
            home: matchRound4Decoded[0],
            away: matchRound4Decoded[1],
            home_points: matchRound4Decoded[2],
            away_points: matchRound4Decoded[3],
            winner: matchRound4Decoded[4]
        },
        winner
    };
}

const getAllRegionDataDecoded = async (
    marchMadness: any,
    GAME_YEAR: number
): Promise<RoundsData> => {
    const allRegionData = await marchMadness.getAllRegionsData(GAME_YEAR);

    const southDecoded = await getRegionDataDecoded(allRegionData[0]);
    const westDecoded = await getRegionDataDecoded(allRegionData[1]);
    const midwestDecoded = await getRegionDataDecoded(allRegionData[2]);
    const eastDecoded = await getRegionDataDecoded(allRegionData[3]);

    const finalData = {
        south: southDecoded,
        west: westDecoded,
        midwest: midwestDecoded,
        east: eastDecoded
    }

    return finalData;
}

const getFinalFourDataDecoded = async (
    marchMadness: any,
    GAME_YEAR: number
): Promise<FinalFour> => {
    const getFinalFourData = await marchMadness.getFinalFourData(GAME_YEAR);
    const [matchesRound1, matchFinal, winner] =
        ethers.utils.defaultAbiCoder.decode(
            ["bytes[2]", "bytes", "string"],
            getFinalFourData
        );

    const round1Decoded = matchesRound1.map((match: any) => {
        const [home, away, home_points, away_points, winner] =
            ethers.utils.defaultAbiCoder.decode(
                ["string", "string", "uint256", "uint256", "string"],
                match
            );
        return { home, away, home_points, away_points, winner };
    });

    const matchFinalDecoded = ethers.utils.defaultAbiCoder.decode(
        ["string", "string", "uint256", "uint256", "string"],
        matchFinal
    );

    return {
        round1: round1Decoded,
        final: {
            home: matchFinalDecoded[0],
            away: matchFinalDecoded[1],
            home_points: matchFinalDecoded[2],
            away_points: matchFinalDecoded[3],
            winner: matchFinalDecoded[4]
        },
        winner: winner
    };
}

//function advanceRound(uint256 year) external
const advanceRound = async (
    marchMadness: any,
    GAME_YEAR: number,
    gasPrice: ethers.BigNumber
): Promise<void> => {
    try {
        const estimatedGas = await marchMadness.estimateGas.advanceRound(GAME_YEAR);
        const gasLimit = estimatedGas.mul(120).div(100);

        console.log(
            `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
        );

        const tx = await marchMadness.advanceRound(GAME_YEAR, {
            gasLimit: gasLimit,
            gasPrice: gasPrice,
        });

        await tx.wait(1);
        console.log(`Round advanced. TX: ${tx.hash}`);
    } catch (error) {
        console.error("Failed to advance round:", error);
    }
}

export const advanceGames: ActionFn = async (
    context: Context,
    event: Event
) => {
    const privateKey = await context.secrets.get("project.addressPrivateKey");
    const rpcUrl = await context.secrets.get("baseSepolia.rpcUrl");
    const marchMadnessAdress = await context.secrets.get("baseSepolia.marchMadness.contract");
    const abiText = await context.secrets.get("marchMadness.abi");
    const abi = JSON.parse(abiText);
    const apiUrl = await context.secrets.get("marchMadness.apiUrl");
    let madnessData;
    const GAME_YEAR = 2021;

    console.log("Getting March Madness data");
    try {
        const response = await axios.get(apiUrl);
        madnessData = response.data;
    } catch (error) {
        console.error("Failed to fetch March Madness data:", error);
        return;
    }

    console.log("Checking on data for March Madness, year:", GAME_YEAR);

    console.log("MarchMadness Contract:", marchMadnessAdress);

    console.log("Fetching wallet");
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);
    console.log("Wallet:", wallet.address);

    const gasPrice = await getGasPrice(provider);

    console.log("Fetching MarchMadness contract");
    let marchMadness: any;
    try {
        marchMadness = new ethers.Contract(marchMadnessAdress, abi, wallet);
    } catch (error) {
        console.error("Failed to fetch contract:", error);
        return;
    }

    console.log("Fetching if there is a tournament contract for this year");
    let tournamentContract;
    try {
        tournamentContract = await marchMadness.tournaments(GAME_YEAR);
    } catch (error) {
        console.error("Failed to fetch tournament contract:", error);
        return;
    }

    if (tournamentContract === "0x0000000000000000000000000000000000000000") {
        tournamentContract = await createNewTournament(
            madnessData,
            marchMadness,
            GAME_YEAR,
            gasPrice,
            context
        );
        if (tournamentContract === "") {
            console.error("Failed to create new tournament contract");
            return;
        }
        console.log("New tournament contract:", tournamentContract);
        return;
    }

    console.log(
        "Tournament contract for Year",
        GAME_YEAR,
        ":",
        tournamentContract
    );

    const getGame = await marchMadness.getGameStatus(GAME_YEAR);
    const [currentRound, status] = ethers.utils.defaultAbiCoder.decode(
        ["uint8", "uint8"],
        getGame
    );

    console.log("Current Round:", currentRound, "Status:", status);

    let advanceRoundTrigger = false;

    console.log("Getting All Region Data");
    const allRegionData = await getAllRegionDataDecoded(marchMadness, GAME_YEAR);

    console.log("Checking for advancing games");

    const regions = [
        {
            name: "SOUTH",
            data: allRegionData.south,
            apiData: {
                round1: (await getMmInfo(madnessData, 1, context)).south,
                round2: (await getMmInfo(madnessData, 2, context)).south,
                round3: (await getMmInfo(madnessData, 3, context)).south,
                round4: (await getMmInfo(madnessData, 4, context)).south
            }
        },
        {
            name: "WEST",
            data: allRegionData.west,
            apiData: {
                round1: (await getMmInfo(madnessData, 1, context)).west,
                round2: (await getMmInfo(madnessData, 2, context)).west,
                round3: (await getMmInfo(madnessData, 3, context)).west,
                round4: (await getMmInfo(madnessData, 4, context)).west
            }
        },
        {
            name: "MIDWEST",
            data: allRegionData.midwest,
            apiData: {
                round1: (await getMmInfo(madnessData, 1, context)).midwest,
                round2: (await getMmInfo(madnessData, 2, context)).midwest,
                round3: (await getMmInfo(madnessData, 3, context)).midwest,
                round4: (await getMmInfo(madnessData, 4, context)).midwest
            }
        },
        {
            name: "EAST",
            data: allRegionData.east,
            apiData: {
                round1: (await getMmInfo(madnessData, 1, context)).east,
                round2: (await getMmInfo(madnessData, 2, context)).east,
                round3: (await getMmInfo(madnessData, 3, context)).east,
                round4: (await getMmInfo(madnessData, 4, context)).east
            }
        }
    ];

    if (currentRound === 0) {
        console.log("Getting First Four Data");
        const firstFourData = await getFirstFourDataDecoded(marchMadness, GAME_YEAR);
        const firstFour = await getFirstFour(madnessData, context);

        let avancar = false;
        firstFourData.matches.forEach((match) => {
            if (match.winner === "") {
                avancar = true;
            }
        });

        if (avancar && status === 0) {
            console.log("Determining First Four Winners");

            if (firstFour.teams.length === 0) {
                console.error("Failed to fetch First Four data");
                return;
            }
            await determineFirstFourWinners(
                marchMadness,
                GAME_YEAR,
                firstFour,
                gasPrice
            );
        } else if (status === 1) {
            const firstGameDate = await getFirstGame(madnessData, context);
            if (firstGameDate < new Date()) {
                console.log("Closing bets for First Four");
                const estimatedGas = await marchMadness.estimateGas.closeBets(GAME_YEAR);
                const gasLimit = estimatedGas.mul(120).div(100);

                console.log(
                    `Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`
                );

                const tx = await marchMadness.closeBets(GAME_YEAR, {
                    gasLimit: gasLimit,
                    gasPrice: gasPrice,
                });

                await tx.wait(1);
                console.log(`Bets closed for Game. TX: ${tx.hash}`);
            }
        }
    } else if (currentRound >= 1 && currentRound < 5 && status === 2) {
        let transactions = 0;
        switch (currentRound) {
            case 1:
                for (const region of regions) {
                    let advance = false;
                    region.data.matchesRound1.forEach((match) => {
                        if (match.winner === "") {
                            advance = true;
                        }
                    });
                    if (advance) {
                        advanceRoundTrigger = false;
                        console.log("Determining Round 1 Winners for", region.name, "Region");
                        await determineRound1Winners(
                            marchMadness,
                            GAME_YEAR,
                            region.name,
                            region.apiData.round1.teams,
                            region.apiData.round1.scores,
                            gasPrice
                        );
                        transactions++;
                    } else {
                        advanceRoundTrigger = true;
                    }
                    if (transactions === 2) {
                        return;
                    }
                }
                if (advanceRoundTrigger) {
                    console.log("Advancing Round");
                    await advanceRound(marchMadness, GAME_YEAR, gasPrice);
                }
                break;
            case 2:
                for (const region of regions) {
                    let advance = false;
                    region.data.matchesRound2.forEach((match) => {

                        if (match.winner === "") {
                            advance = true;
                        }
                    });
                    if (advance) {
                        advanceRoundTrigger = false;
                        console.log("Determining Round 2 Winners for", region.name, "Region");
                        await determineRound2Winners(
                            marchMadness,
                            GAME_YEAR,
                            region.name,
                            region.apiData.round2.teams,
                            region.apiData.round2.scores,
                            gasPrice
                        );
                        transactions++;
                    } else {
                        advanceRoundTrigger = true;
                    }
                    if (transactions === 2) {
                        return;
                    }
                }
                if (advanceRoundTrigger) {
                    console.log("Advancing Round");
                    await advanceRound(marchMadness, GAME_YEAR, gasPrice);
                }
                break;
            case 3:
                //iterate all four regions
                for (const region of regions) {
                    let advance = false;
                    region.data.matchesRound3.forEach((match) => {

                        if (match.winner === "") {
                            advance = true;
                        }
                    });
                    if (advance) {
                        advanceRoundTrigger = false;
                        console.log("Determining Round 3 Winners for", region.name, "Region");
                        await determineRound3Winners(
                            marchMadness,
                            GAME_YEAR,
                            region.name,
                            region.apiData.round3.teams,
                            region.apiData.round3.scores,
                            gasPrice
                        );
                        transactions++;
                    } else {
                        advanceRoundTrigger = true;
                    }
                    if (transactions === 2) {
                        return;
                    }
                }
                if (advanceRoundTrigger) {
                    console.log("Advancing Round");
                    await advanceRound(marchMadness, GAME_YEAR, gasPrice);
                }
                break;
            case 4:
                for (const region of regions) {
                    if (region.data.matchRound4.winner === "") {
                        advanceRoundTrigger = false;
                        console.log("Determining Round 4 Winner for", region.name, "Region");
                        await determineRound4Winners(
                            marchMadness,
                            GAME_YEAR,
                            region.name,
                            region.apiData.round4.teams[0],
                            region.apiData.round4.teams[1],
                            region.apiData.round4.scores[0],
                            region.apiData.round4.scores[1],
                            gasPrice
                        );
                        transactions++;
                    } else {
                        advanceRoundTrigger = true;
                    }
                    if (transactions === 2) {
                        return;
                    }
                }
                if (advanceRoundTrigger) {
                    console.log("Advancing Round");
                    await advanceRound(marchMadness, GAME_YEAR, gasPrice);
                }
                break;
            default:
                break;
        }
    } else if (currentRound === 5) {
        console.log("Getting Final Four Data");
        const finalFourData = await getFinalFourDataDecoded(marchMadness, GAME_YEAR);
        let advance = false;
        finalFourData.round1.forEach((match) => {
            if (match.winner === "") {
                advance = true;
            }
        });
        if (advance) {
            console.log("Determining Final Four Winners");
            const finalFourApiData = await getFinalFour(madnessData, context);
            await determineFinalFourWinners(
                marchMadness,
                GAME_YEAR,
                finalFourApiData.teams,
                finalFourApiData.scores,
                gasPrice
            );

        }
    } else if (currentRound === 6 && status === 2) {
        //matchFinal result
        console.log("Getting Final Four Data");
        const finalFourData = await getFinalFourDataDecoded(marchMadness, GAME_YEAR);


        let advance = finalFourData.winner === "" ? true : false;
        if (advance) {
            console.log("Determining Final Winner");
            const finalMatch = await getFinalMatch(madnessData, context);

            console.log("Final Match Data:", finalMatch);
            console.log("Final Four Data:", finalFourData);
            await determineChampion(
                marchMadness,
                GAME_YEAR,
                finalMatch.home,
                finalMatch.away,
                finalMatch.home_points,
                finalMatch.away_points,
                gasPrice
            );
        }
    } else {
        console.log("Tournament is over, no more games to advance");
        const allRegionData = await getAllRegionDataDecoded(marchMadness, GAME_YEAR);
        const finalFourData = await getFinalFourDataDecoded(marchMadness, GAME_YEAR);
        console.log("Regions All Data:", JSON.stringify(allRegionData, null, 2));
        console.log("Final Four Data:", JSON.stringify(finalFourData, null, 2));
    }

};
