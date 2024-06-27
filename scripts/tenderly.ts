import { ActionFn, Context, Event } from "@tenderly/actions";

import { ethers } from "ethers";
import axios from 'axios';

interface Coin {
    id: number;
    symbol: string;
}

const getRandomUniqueElements = (arr: Coin[], n: number): Coin[] => {
    const uniqueById = Array.from(new Map(arr.map(item => [item['id'], item])).values());

    let result = new Array(n),
        len = uniqueById.length,
        taken = new Array(len);
    if (n > len)
        throw new RangeError("getRandomUniqueElements: more elements taken than available");
    while (n--) {
        const x = Math.floor(Math.random() * len);
        result[n] = uniqueById[x in taken ? taken[x] : x];
        taken[x] = --len in taken ? taken[len] : len;
    }
    return result;
};

const getCoinsTop = async (limit: number, maxCoins: number, context: Context): Promise<Coin[]> => {
    const apiKey = await context.secrets.get("project.cmcAPIKey");
    const url = `https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest`;

    try {
        const response = await axios.get(url, {
            params: {
                start: 1,
                limit: limit,
                sort: 'market_cap'
            },
            headers: {
                'X-CMC_PRO_API_KEY': apiKey
            },
            timeout: 5000
        });

        const coinsData = response.data.data;

        const selectedCoins = getRandomUniqueElements(coinsData, maxCoins);

        const formattedCoins = selectedCoins.map(coin => ({ id: coin.id, symbol: coin.symbol }));

        return formattedCoins;
    } catch (error) {
        console.error('CoinMarketCap API call failed:', error);
        return [];
    }
}

const getPriceCMC = async (coin: string, context: Context): Promise<any> => {
    const apiKey = await context.secrets.get("project.cmcAPIKey");
    const url = `https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest`;

    try {
        const response = await axios.get(url, {
            params: {
                symbol: coin
            },
            headers: {
                'X-CMC_PRO_API_KEY': apiKey
            },
            timeout: 5000
        });

        return response.data.data;
    } catch (error) {
        console.error('CoinMarketCap API call failed:', error);
        return [];
    }
}

// Function to decode the data returned by the getActiveGamesActualCoins() function
const decodeActiveGamesActualCoins = (encodedGames: string[]): { game_id: number; coins: string[] }[] => {
    const decodedGames = encodedGames.map((encodedGame) => {
        const decoded = ethers.utils.defaultAbiCoder.decode(['uint256', 'string[]', 'uint256[]'], encodedGame);

        return {
            game_id: decoded[0].toNumber(),
            coins: decoded[1],
            prices: decoded[2]
        };
    });

    return decodedGames;
};

// Function to create the calldata for the createGame function
const createCalldataForNewGame = (newGameCoins: { id: number; symbol: string }[]) => {
    const cmcIds = newGameCoins.map(coin => coin.id);
    const symbols = newGameCoins.map(coin => coin.symbol);

    // Encode the data for the createGame function
    const calldata = ethers.utils.defaultAbiCoder.encode(
        ["uint256[]", "string[]"],
        [cmcIds, symbols]
    );

    return calldata;
};

const updateCoinsList = (coins: string, decodedGames: { game_id: number, coins: string[] }[]) => {
    // Convert the comma-separated string of symbols to a set
    let symbolsSet = new Set(coins.split(','));

    decodedGames.forEach(game => {
        game.coins.forEach(coin => {
            // Adds the coin to the set if it's not already there
            if (coin.trim() && !symbolsSet.has(coin)) {
                symbolsSet.add(coin);
            }
        });
    });

    return Array.from(symbolsSet).join(',');
};

const calculateGameResults = (decodedGames: any[], prices: any) => {
    const resultGames = decodedGames.map(game => {
        const variations = new Array(8).fill(0);
        const actualPrices = new Array(8).fill(0);
        const winners = new Array(8).fill(0);
        const pricesWinners = new Array(8).fill(0);

        for (let index = 0; index < game.coins.length; index += 2) {
            if (!game.coins[index]) {
                continue;
            }
            const priceCurrent = Math.floor(prices[game.coins[index]].quote.USD.price * 10 ** 6);
            const priceNext = Math.floor(prices[game.coins[index + 1]].quote.USD.price * 10 ** 6);

            const variationCurrent = (priceCurrent - game.prices[index]) / game.prices[index];
            const variationNext = (priceNext - game.prices[index + 1]) / game.prices[index + 1];

            variations[index] = variationCurrent;
            variations[index + 1] = variationNext;

            actualPrices[index] = priceCurrent;
            actualPrices[index + 1] = priceNext;

            // Determina o vencedor do par
            if (variationCurrent > variationNext) {
                winners[index / 2] = prices[game.coins[index]].id;
                pricesWinners[index / 2] = priceCurrent;
            } else {
                winners[index / 2] = prices[game.coins[index + 1]].id;
                pricesWinners[index / 2] = priceNext;
            }
        }

        return {
            game_id: game.game_id,
            coins: game.coins,
            prices: actualPrices,
            variations: variations.map(v => v || 0),
            winners,
            pricesWinners
        };
    });

    return resultGames;
};

function createDataUpdate(resultGames: any[]) {
    const gameIds = resultGames.map(game => game.game_id);
    const prices = resultGames.map(game => ethers.utils.defaultAbiCoder.encode(["uint256[]"], [game.prices]));
    const pricesWinners = resultGames.map(game => ethers.utils.defaultAbiCoder.encode(["uint256[]"], [game.pricesWinners]));
    const winners = resultGames.map(game => ethers.utils.defaultAbiCoder.encode(["uint256[]"], [game.winners]));

    const dataUpdate = ethers.utils.defaultAbiCoder.encode(
        ["uint256[]", "bytes[]", "bytes[]", "bytes[]"],
        [gameIds, prices, pricesWinners, winners]
    );

    return dataUpdate;
}

const getGasPrice = async (polygonScanUrl: string, polygonScanKey: string): Promise<ethers.BigNumber> => {
    try {
        const response = await axios.get(`${polygonScanUrl}?module=gastracker&action=gasoracle&apikey=${polygonScanKey}`);
        const proposedGasPrice = response.data.result.ProposeGasPrice;
        const gasPriceGwei = ethers.utils.parseUnits(proposedGasPrice, 'gwei');

        // Increase the gas price by 10%
        const increasedGasPrice = gasPriceGwei.mul(110).div(100);
        return increasedGasPrice;
    } catch (error) {
        console.error('Failed to fetch gas price:', error);
        return ethers.utils.parseUnits('10', 'gwei');
    }
};


export const advanceGames: ActionFn = async (context: Context, event: Event) => {
    const privateKey = await context.secrets.get("project.addressPrivateKey");
    const polygonScanKey = await context.secrets.get("project.polygonScanKey");
    const polygonScanUrl = await context.storage.getStr("mumbai.api");
    const rpcUrl = await context.secrets.get("mumbai.rpcUrl");
    const CONTRACT_ADDRESS = await context.storage.getStr('ace8.test.contractMumbai');
    const abi = await context.storage.getJson('ace8.abi');

    console.log("Fetching coins for a new game");
    const newGameCoins = await getCoinsTop(100, 8, context);
    const newGameCalldata = createCalldataForNewGame(newGameCoins);
    let coins = newGameCoins.map(coin => coin.symbol).join(',');

    console.log("Fetching wallet");
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);

    console.log("Fetching ACE contract");
    let aceContract: any;
    try {
        aceContract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);
    } catch (error) {
        console.error('Failed to fetch contract:', error);
        return;
    }

    let gamesData: string[];
    try {
        gamesData = await aceContract.getActiveGamesActualCoins();
    } catch (error) {
        console.error('Failed to fetch active games:', error);
        return;
    }
    const decodedGames = decodeActiveGamesActualCoins(gamesData);

    coins = updateCoinsList(coins, decodedGames);

    const prices = await getPriceCMC(coins, context);
    if (!prices || prices.length === 0) {
        console.error('Failed to fetch prices');
        return;
    }

    const resultGames = calculateGameResults(decodedGames, prices);
    const updateGamesCalldata = createDataUpdate(resultGames);
    let estimatedGas: ethers.BigNumber;
    let gasLimit: ethers.BigNumber;

    try {
        estimatedGas = await aceContract.estimateGas.performGames(newGameCalldata, updateGamesCalldata);
        gasLimit = estimatedGas.mul(130).div(100);
    } catch (error) {
        console.error('Failed to estimate gas:', error);
        return;
    }
    const gasPrice = await getGasPrice(polygonScanUrl, polygonScanKey);

    console.log(`Estimated gas: ${estimatedGas.toString()}, adjusted gas limit: ${gasLimit.toString()}`);

    try {
        const tx = await aceContract.performGames(newGameCalldata, updateGamesCalldata, {
            gasLimit: gasLimit,
            gasPrice: gasPrice
        });

        await tx.wait();
        console.log(`Games successfully updated. TX: ${tx.hash}`);
    } catch (error) {
        console.error('Failed to perform games:', error);
    };
};