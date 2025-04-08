// Web3 provider and signer setup
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

// Contract instances (placeholders for addresses and ABIs to be filled in)
const zpeContract = new ethers.Contract("0xYourZPEAddress", zpeABI, signer);
const zpwContract = new ethers.Contract("0xYourZPWAddress", zpwABI, signer);
const zppContract = new ethers.Contract("0xYourZPPAddress", zppABI, signer);
const deviceContract = new ethers.Contract("0xYourDeviceConnectAddress", deviceABI, signer);
const usdcContract = new ethers.Contract("0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", usdcABI, signer);
const adWatchContract = new ethers.Contract("0xYourAdWatchAddress", adWatchABI, signer);
const homeTeamBetsContract = new ethers.Contract("0xYourHomeTeamBetsAddress", homeTeamBetsABI, signer);
const gerastyxOpolContract = new ethers.Contract("0xYourGerastyxOpolAddress", gerastyxOpolABI, signer);
const greyStaxContract = new ethers.Contract("0xYourGreyStaxAddress", greyStaxABI, signer);
const digitalStockNFTContract = new ethers.Contract("0xYourDigitalStockNFTAddress", digitalStockNFTABI, signer);
const stakingContract = new ethers.Contract("0xYourGoateStakingAddress", goateStakingABI, signer);
const lendingContract = new ethers.Contract("0xYourLendingAddress", lendingABI, signer);
const interoperabilityContract = new ethers.Contract("0xYourInteroperabilityAddress", interoperabilityABI, signer);
const scratchOffContract = new ethers.Contract("0xYourScratchOffNFTAddress", scratchOffABI, signer);
const goateTokenContract = new ethers.Contract("0xYourGoateTokenAddress", goateABI, signer); // New
const usdMediatorContract = new ethers.Contract("0xYourUSDMediatorAddress", usdMediatorABI, signer); // New
const mediator = new USDMediator(); // Assuming USDMediator is a JS class from usd-mediator.js

// State variables
let currentUser, isLoggedIn = false;
const db = { users: {}, devices: {}};

// Plaid integration
const plaidHandler = Plaid.create({
    token: "YOUR_PLAID_PUBLIC_TOKEN",
    onSuccess: async (publicToken) => {
        const response = await fetch('/plaid/exchange_public_token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ public_token: publicToken })
        });
        const { access_token } = await response.json();
        const creditResponse = await fetch('/plaid/credit_report', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ access_token })
        });
        const creditData = await creditResponse.json();
        console.log("Credit Score:", creditData.credit_score);
    },
    onExit: (err) => console.error(err)
});

// Update user balances including Goate Token
async function updateBalances() {
    const userAddress = await signer.getAddress();
    document.getElementById('usd-balance').textContent = ethers.utils.formatUnits(await usdcContract.balanceOf(userAddress), 6);
    document.getElementById('zeropoint-balance').textContent = ethers.utils.formatUnits(await zpeContract.balanceOf(userAddress), 3);
    document.getElementById('zeropointwifi-balance').textContent = ethers.utils.formatUnits(await zpwContract.balanceOf(userAddress), 2);
    document.getElementById('zeropointphone-balance').textContent = ethers.utils.formatUnits(await zppContract.balanceOf(userAddress), 2);
    document.getElementById('gyst-balance').textContent = ethers.utils.formatUnits(await greyStaxContract.balanceOf(userAddress), 18);
    document.getElementById('goate-balance').textContent = ethers.utils.formatUnits(await goateTokenContract.balanceOf(userAddress), 18);
}

// Initialize digital stocks
async function initializeStocks() {
    const response = await fetch('https://api.alpaca.markets/v2/assets', {
        headers: { 
            'APCA-API-KEY-ID': 'YOUR_ALPACA_KEY', 
            'APCA-API-SECRET-KEY': 'YOUR_ALPACA_SECRET' 
        }
    });
    const stocks = await response.json();
    for (const stock of stocks) {
        await digitalStockNFTContract.mintStock("0xYourOwnerAddress", stock.symbol);
    }
}

// Load stock list
async function loadStocks() {
    const stockList = document.getElementById('stock-list');
    stockList.innerHTML = '';
    const tokenCount = await digitalStockNFTContract.tokenCounter();
    for (let i = 0; i < tokenCount; i++) {
        const symbol = await digitalStockNFTContract.stockSymbols(i);
        stockList.innerHTML += `
            <div class="stock-card">
                <h3>${symbol}</h3>
                <input type="number" id="amount-${i}" placeholder="Amount (USDC)">
                <select id="chain-${i}">
                    <option value="1">Ethereum</option>
                    <option value="512">Stellar</option>
                </select>
                <button onclick="buyStock(${i})">Buy</button>
                <button onclick="sellStock(${i})">Sell</button>
            </div>
        `;
    }
}

// Buy stock
async function buyStock(tokenId) {
    const amount = ethers.utils.parseUnits(document.getElementById(`amount-${tokenId}`).value, 6);
    const chainId = document.getElementById(`chain-${tokenId}`).value;
    await confirmTransaction(`Buy ${await digitalStockNFTContract.stockSymbols(tokenId)} for ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await usdcContract.approve(digitalStockNFTContract.address, amount);
        await digitalStockNFTContract.buyStock(tokenId, amount, chainId);
        updateBalances();
        loadStocks();
    });
}

// Sell stock
async function sellStock(tokenId) {
    const amount = ethers.utils.parseUnits(document.getElementById(`amount-${tokenId}`).value, 6);
    await confirmTransaction(`Sell ${await digitalStockNFTContract.stockSymbols(tokenId)} for ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await digitalStockNFTContract.sellStock(tokenId, amount, "USDC", 1);
        updateBalances();
        loadStocks();
    });
}

// Load HomeTeamBets games
async function loadGames() {
    const gamesList = document.getElementById('games-list');
    gamesList.innerHTML = '';
    const gameCount = await homeTeamBetsContract.gameCount();
    for (let i = 0; i < gameCount; i++) {
        const game = await homeTeamBetsContract.games(i);
        gamesList.innerHTML += `
            <div class="game-card">
                <h3>${game.homeTeam} vs ${game.awayTeam}</h3>
                <p>Start: ${new Date(game.startTime * 1000).toLocaleString()}</p>
                <p>Pool: ${ethers.utils.formatUnits(game.totalPool, 6)} USDC</p>
                <select id="bet-type-${i}">
                    <option value="0">Win</option>
                    <option value="1">Lose</option>
                    <option value="2">Tie</option>
                </select>
                <input type="checkbox" id="overtime-${i}"> Overtime?
                <input type="number" id="bet-amount-${i}" placeholder="Bet Amount (USDC)">
                <button onclick="placeBet(${i})">Place Bet</button>
            </div>
        `;
    }
}

// Place a bet
async function placeBet(gameId) {
    const amount = ethers.utils.parseUnits(document.getElementById(`bet-amount-${gameId}`).value, 6);
    const betType = document.getElementById(`bet-type-${gameId}`).value;
    const overtime = document.getElementById(`overtime-${gameId}`).checked;
    await confirmTransaction(`Place ${ethers.utils.formatUnits(amount, 6)} USDC bet on Game ${gameId}?`, async () => {
        await usdcContract.approve(homeTeamBetsContract.address, amount);
        await homeTeamBetsContract.placeBet(gameId, amount, betType, overtime);
        updateBalances();
        loadGames();
    });
}

// Load staking iframe
async function loadStaking() {
    const stakingContainer = document.getElementById('staking-container');
    stakingContainer.innerHTML = `<iframe src="unreal://goatestaking" width="100%" height="100%"></iframe>`;
}

// Load scratch-off iframe
async function loadScratchOff() {
    const scratchOffContainer = document.getElementById('scratch-off-container');
    scratchOffContainer.innerHTML = `<iframe src="unreal://scratchoffnft" width="100%" height="100%"></iframe>`;
}

// Scratch an NFT
async function scratchNFT(mode, asset, chainId) {
    const amounts = { "Pennies": "1", "Nickels": "5", "Dimes": "10", "Quarters": "25", "Dollars": "100" };
    const amount = ethers.utils.parseUnits(amounts[mode], 6);
    await confirmTransaction(`Scratch ${mode} NFT for ${amounts[mode]} ${asset} on Chain ${chainId}?`, async () => {
        const token = new ethers.Contract(interoperabilityContract.tokenMap(chainId, asset), erc20ABI, signer);
        await token.approve(scratchOffContract.address, amount);
        await scratchOffContract.scratch(asset, mode === "Pennies" ? 0 : mode === "Nickels" ? 1 : mode === "Dimes" ? 2 : mode === "Quarters" ? 3 : 4, chainId);
        updateBalances();
    });
}

// Stake assets
async function stake(asset, amount, duration) {
    await confirmTransaction(`Stake ${amount} ${asset} for ${duration} seconds?`, async () => {
        const token = new ethers.Contract(interoperabilityContract.tokenMap(1, asset), erc20ABI, signer);
        await token.approve(stakingContract.address, amount);
        await stakingContract.stake(asset, amount, duration);
        updateBalances();
    });
}

// Lending functions
async function lend(amount) {
    await confirmTransaction(`Lend ${amount} USDC?`, async () => {
        await usdcContract.approve(lendingContract.address, amount);
        await lendingContract.lend(amount);
        updateBalances();
    });
}

async function borrow(amount) {
    await confirmTransaction(`Borrow ${amount} USDC?`, async () => {
        await lendingContract.borrow(amount);
        updateBalances();
    });
}

async function repay(amount) {
    await confirmTransaction(`Repay ${amount} USDC?`, async () => {
        await usdcContract.approve(lendingContract.address, amount);
        await lendingContract.repay(amount);
        updateBalances();
    });
}

// Start GerastyxOpol game
async function startGame(mode) {
    const sessionId = await gerastyxOpolContract.sessionCount();
    if (mode === "FreePlay") {
        await confirmTransaction("Start Free Play session?", async () => {
            await gerastyxOpolContract.startSession(0, 0);
            loadGame(sessionId);
        });
    } else {
        const fee = mode === "Reasonable" ? "1" : mode === "Gambling" ? "5" : "20";
        await confirmTransaction(`Start ${mode} session for ${fee} USDC?`, async () => {
            await usdcContract.approve(gerastyxOpolContract.address, ethers.utils.parseUnits(fee, 6));
            await gerastyxOpolContract.startSession(mode === "Reasonable" ? 1 : mode === "Gambling" ? 2 : 3, ethers.utils.parseUnits(fee, 6));
            loadGame(sessionId);
        });
    }
}

// Load GerastyxOpol game iframe
function loadGame(sessionId) {
    const gameContainer = document.getElementById('game-container');
    gameContainer.innerHTML = `<iframe src="unreal://gerastyxopol?session=${sessionId}" width="100%" height="100%"></iframe>`;
}

// Confirmation modal logic
async function confirmTransaction(message, callback) {
    const modal = document.getElementById('confirmation-modal');
    const messageEl = document.getElementById('modal-message');
    const yesBtn = document.getElementById('modal-yes');
    const noBtn = document.getElementById('modal-no');
    const pinSection = document.getElementById('pin-section');
    const pinInput = document.getElementById('pin-input');
    const pinSubmit = document.getElementById('pin-submit');

    messageEl.textContent = message;
    modal.style.display = 'flex';
    pinSection.style.display = 'none';

    return new Promise((resolve) => {
        yesBtn.onclick = () => {
            pinSection.style.display = 'block';
            yesBtn.style.display = 'none';
            noBtn.style.display = 'none';
        };
        noBtn.onclick = () => {
            modal.style.display = 'none';
            resolve(false);
        };
        pinSubmit.onclick = () => {
            if (pinInput.value.length === 4) {
                modal.style.display = 'none';
                callback();
                resolve(true);
            }
        };
    });
}

// Load user devices
async function loadDevices() {
    const userAddress = await signer.getAddress();
    const devices = await deviceContract.getUserDevices(userAddress);
    const container = document.getElementById('devices-container');
    container.innerHTML = devices.map(device => `
        <div class="device-card">
            <span>${device.deviceId} (Modals: ${device.modalCount})</span>
            <div class="slider-group">
                <button class="slider-btn on ${device.isActive ? 'active' : ''}" data-device="${device.deviceId}">On</button>
                <button class="slider-btn off ${!device.isActive ? 'active' : ''}" data-device="${device.deviceId}">Off</button>
            </div>
        </div>
    `).join('');
}

// Watch ads
async function watchAd(adType) {
    await confirmTransaction(`Watch ${adType} Ad?`, async () => {
        const adContainer = document.createElement("div");
        adContainer.style.position = "fixed";
        adContainer.style.top = "0";
        adContainer.style.left = "0";
        adContainer.style.width = "100vw";
        adContainer.style.height = "100vh";
        adContainer.style.background = "black";
        adContainer.style.color = "#FFD700";
        adContainer.style.display = "flex";
        adContainer.style.justifyContent = "center";
        adContainer.style.alignItems = "center";
        adContainer.innerHTML = `<p>Watching ${adType} Ad... (30s)</p>`;
        document.body.appendChild(adContainer);

        await new Promise(resolve => setTimeout(resolve, 30000));
        document.body.removeChild(adContainer);

        await mediator.handleAdWatch(adType, await signer.getAddress());
        updateBalances();
    });
}

// Airdrop Goate Tokens
async function airdropGoate() {
    const achievementPoints = 1; // Example value, could be dynamic
    await confirmTransaction(`Airdrop ${achievementPoints * 10} $GOATE for ${achievementPoints} achievement points?`, async () => {
        await goateTokenContract.recordAchievement(await signer.getAddress(), achievementPoints);
        updateBalances();
    });
}

// Search sports data
async function searchSportsData(query) {
    const resultDiv = document.getElementById('sports-data-result');
    try {
        const data = await usdMediatorContract.readSportsData(query);
        resultDiv.innerHTML = `<p>Sports Data API: ${data}</p>`;
    } catch (error) {
        resultDiv.innerHTML = `<p>Error: ${error.message}</p>`;
    }
}

// Update UI based on login state
function updateUI() {
    document.getElementById('logged-in').style.display = isLoggedIn ? 'block' : 'none';
    document.getElementById('not-logged-in').style.display = isLoggedIn ? 'none' : 'block';
    document.getElementById('navigation').style.display = isLoggedIn ? 'flex' : 'none';
    document.getElementById('signup-login').style.display = isLoggedIn ? 'none' : 'inline';
    document.getElementById('user-email').style.display = isLoggedIn ? 'inline' : 'none';
    document.getElementById('logout').style.display = isLoggedIn ? 'inline' : 'none';
    if (isLoggedIn) {
        document.getElementById('user-email').textContent = currentUser;
        updateBalances();
        loadDevices();
    }
}

// DOM content loaded event listener
document.addEventListener('DOMContentLoaded', async () => {
    await provider.send("eth_requestAccounts", []);
    await initializeStocks();

    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    hamburger.addEventListener('click', () => {
        navMenu.classList.toggle('active');
        hamburger.classList.toggle('open');
        if (hamburger.classList.contains('open')) {
            hamburger.children[0].style.transform = 'rotate(45deg) translate(5px, 5px)';
            hamburger.children[1].style.opacity = '0';
            hamburger.children[2].style.transform = 'rotate(-45deg) translate(5px, -5px)';
        } else {
            hamburger.children[0].style.transform = 'none';
            hamburger.children[1].style.opacity = '1';
            hamburger.children[2].style.transform = 'none';
        }
    });

    document.getElementById('signup-login').addEventListener('click', () => {
        currentUser = "user@example.com";
        isLoggedIn = true;
        updateUI();
    });

    document.getElementById('logout').addEventListener('click', () => {
        isLoggedIn = false;
        currentUser = null;
        updateUI();
    });

    document.getElementById('consume-zpe').addEventListener('click', async () => {
        const amount = document.getElementById('payment-amount').value;
        await confirmTransaction(`Consume ${amount || 1} $ZPE?`, async () => {
            await zpeContract.consumeForService(ethers.utils.parseUnits(amount || "1", 3));
            updateBalances();
        });
    });

    document.getElementById('consume-zpw').addEventListener('click', async () => {
        const amount = document.getElementById('payment-amount').value;
        await confirmTransaction(`Consume ${amount || 1} $ZPW?`, async () => {
            await zpwContract.burn(ethers.utils.parseUnits(amount || "1", 2));
            updateBalances();
        });
    });

    document.getElementById('subscribe-zpp').addEventListener('click', async () => {
        await confirmTransaction(`Subscribe with $ZPP?`, async () => {
            await zppContract.subscribe();
            updateBalances();
        });
    });

    document.getElementById('add-device').addEventListener('click', async () => {
        const deviceId = document.getElementById('device-id').value;
        await confirmTransaction(`Add Device ${deviceId}?`, async () => {
            await deviceContract.addDevice(deviceId);
            loadDevices();
        });
    });

    document.getElementById('watch-google-ad').addEventListener('click', () => watchAd("Google"));
    document.getElementById('watch-pi-ad').addEventListener('click', () => watchAd("Pi"));
    document.getElementById('watch-youtube-ad').addEventListener('click', () => watchAd("YouTube"));

    document.getElementById('free-play').addEventListener('click', () => startGame("FreePlay"));
    document.getElementById('reasonable').addEventListener('click', () => startGame("Reasonable"));
    document.getElementById('gambling').addEventListener('click', () => startGame("Gambling"));
    document.getElementById('rich').addEventListener('click', () => startGame("Rich"));

    document.getElementById('connect-plaid').addEventListener('click', () => plaidHandler.open());

    // New event listeners
    document.getElementById('airdrop-goate').addEventListener('click', airdropGoate);
    document.getElementById('sports-search').addEventListener('input', (e) => searchSportsData(e.target.value));

    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
            const section = document.querySelector(link.getAttribute('href'));
            section.classList.add('active');
            navMenu.classList.remove('active');
            hamburger.classList.remove('open');
            hamburger.children[0].style.transform = 'none';
            hamburger.children[1].style.opacity = '1';
            hamburger.children[2].style.transform = 'none';

            // Load section-specific content
            if (link.getAttribute('href') === '#digital-stocks') loadStocks();
            if (link.getAttribute('href') === '#hometeambets') loadGames();
            if (link.getAttribute('href') === '#goate-staking') loadStaking();
            if (link.getAttribute('href') === '#scratch-off') loadScratchOff();
        });
    });
});
