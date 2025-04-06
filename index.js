const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
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
const mediator = new USDMediator();
let currentUser, isLoggedIn = false;
const db = { users: {}, devices: {} };

// Plaid Integration
const plaidHandler = Plaid.create({
    token: "YOUR_PLAID_PUBLIC_TOKEN", // Replace with real token from Plaid Dashboard
    onSuccess: async (publicToken, metadata) => {
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
        // Update credit score (simplified)
        console.log(`Credit Score: ${creditData.credit_score}`);
    },
    onExit: (err) => console.error(err)
});

async function updateBalances() {
    const userAddress = await signer.getAddress();
    document.getElementById('zeropoint-balance').textContent = ethers.utils.formatUnits(await zpeContract.balanceOf(userAddress), 3);
    document.getElementById('zeropointwifi-balance').textContent = ethers.utils.formatUnits(await zpwContract.balanceOf(userAddress), 2);
    document.getElementById('zeropointphone-balance').textContent = ethers.utils.formatUnits(await zppContract.balanceOf(userAddress), 2);
    document.getElementById('usd-balance').textContent = ethers.utils.formatUnits(await usdcContract.balanceOf(userAddress), 6);
    document.getElementById('gyst-balance').textContent = ethers.utils.formatUnits(await greyStaxContract.balanceOf(userAddress), 18);
}

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
    document.querySelectorAll('.slider-btn').forEach(btn => {
        btn.addEventListener('click', async () => {
            const deviceId = btn.dataset.device;
            const isOn = btn.classList.contains('on');
            if (isOn && !btn.classList.contains('active')) {
                await deviceContract.addDevice(deviceId);
            } else if (!isOn && btn.classList.contains('active')) {
                await deviceContract.disconnectDevice(deviceId);
            }
            loadDevices();
        });
    });
}

async function loadTransactionHistory() {
    const userAddress = await signer.getAddress();
    const history = await adWatchContract.getTransactionHistory(userAddress);
    const historyList = document.getElementById('history-list');
    historyList.innerHTML = history.map(tx => `
        <li>${tx.adType} - ${ethers.utils.formatUnits(tx.payout, 6)} USDC - ${new Date(tx.timestamp * 1000).toLocaleString()}</li>
    `).join('');
}

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
        loadTransactionHistory();
    });
}

async function loadGames() {
    const gameCount = await homeTeamBetsContract.gameCount();
    const gamesList = document.getElementById('games-list');
    gamesList.innerHTML = '';

    for (let i = 0; i < gameCount; i++) {
        const game = await homeTeamBetsContract.games(i);
        if (!game.completed) {
            gamesList.innerHTML += `
                <div class="game-card">
                    <h3>${game.homeTeam} vs ${game.awayTeam}</h3>
                    <p>Starts: ${new Date(game.startTime * 1000).toLocaleString()}</p>
                    <p>Total Pool: ${ethers.utils.formatUnits(game.totalPool, 6)} USDC</p>
                    <select id="bet-type-${i}">
                        <option value="0">Win</option>
                        <option value="1">Lose</option>
                        <option value="2">Tie</option>
                    </select>
                    <select id="overtime-${i}">
                        <option value="yes">Overtime Yes</option>
                        <option value="no">Overtime No</option>
                    </select>
                    <input type="number" id="bet-amount-${i}" placeholder="Amount (USDC)" step="0.01">
                    <button onclick="placeBet(${i})" ${!game.isActive ? 'disabled' : ''} class="disney-button">Place Bet</button>
                </div>
            `;
        }
    }
}

async function placeBet(gameId) {
    const amount = ethers.utils.parseUnits(document.getElementById(`bet-amount-${gameId}`).value, 6);
    const betType = parseInt(document.getElementById(`bet-type-${gameId}`).value);
    const overtime = document.getElementById(`overtime-${gameId}`).value === "yes";
    await confirmTransaction(`Place bet of ${ethers.utils.formatUnits(amount, 6)} USDC on Game ${gameId}?`, async () => {
        const tx = await usdcContract.approve(homeTeamBetsContract.address, amount);
        await tx.wait();
        const betTx = await homeTeamBetsContract.placeBet(gameId, amount, betType, overtime);
        await betTx.wait();
        updateBalances();
        loadBetHistory();
        loadGames();
    });
}

async function loadBetHistory() {
    const userAddress = await signer.getAddress();
    const history = await homeTeamBetsContract.getTransactionHistory(userAddress);
    const historyList = document.getElementById('bet-history-list');
    historyList.innerHTML = history.map(bet => {
        const betTypeStr = bet.betType === 0 ? 'Win' : bet.betType === 1 ? 'Lose' : 'Tie';
        return `<li>${ethers.utils.formatUnits(bet.amount, 6)} USDC - ${betTypeStr} - Overtime: ${bet.overtime ? 'Yes' : 'No'} - ${new Date(bet.timestamp * 1000).toLocaleString()}</li>`;
    }).join('');
}

async function startGame(mode) {
    const sessionId = await gerastyxOpolContract.sessionCount();
    await confirmTransaction(`Start ${mode} session?`, async () => {
        if (mode === "FreePlay") {
            await gerastyxOpolContract.startSession(0, { value: 0 });
        } else {
            const fee = mode === "Reasonable" ? "1" : mode === "Gambling" ? "5" : "20";
            await usdcContract.approve(gerastyxOpolContract.address, ethers.utils.parseUnits(fee, 6));
            await gerastyxOpolContract.startSession(mode === "Reasonable" ? 1 : mode === "Gambling" ? 2 : 3, ethers.utils.parseUnits(fee, 6));
        }
        loadGame(sessionId);
    });
}

function loadGame(sessionId) {
    const gameContainer = document.getElementById('game-container');
    gameContainer.innerHTML = `<iframe src="unreal://gerastyxopol?session=${sessionId}" width="100%" height="100%"></iframe>`;
}

async function initializeStocks() {
    const response = await fetch('https://api.alpaca.markets/v2/assets', {
        headers: { 'APCA-API-KEY-ID': 'YOUR_ALPACA_KEY', 'APCA-API-SECRET-KEY': 'YOUR_ALPACA_SECRET' }
    });
    const stocks = await response.json();
    for (const stock of stocks) {
        await digitalStockNFTContract.mintStock("0xYourOwnerAddress", stock.symbol);
    }
}

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
                    <!-- Add other chains -->
                </select>
                <button onclick="buyStock(${i})" class="disney-button">Buy</button>
                <button onclick="sellStock(${i})" class="disney-button">Sell</button>
            </div>
        `;
    }
}

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

async function sellStock(tokenId) {
    const amount = ethers.utils.parseUnits(document.getElementById(`amount-${tokenId}`).value, 6);
    await confirmTransaction(`Sell ${await digitalStockNFTContract.stockSymbols(tokenId)} for ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await digitalStockNFTContract.sellStock(tokenId, amount, "USDC", 1);
        updateBalances();
        loadStocks();
    });
}

function loadStaking() {
    const stakingContainer = document.getElementById('staking-container');
    stakingContainer.innerHTML = `<iframe src="unreal://goatestaking" width="100%" height="100%"></iframe>`;
}

async function stake(asset, amount, duration) {
    await confirmTransaction(`Stake ${ethers.utils.formatUnits(amount, 6)} ${asset} for ${duration} seconds?`, async () => {
        const token = new ethers.Contract(interoperabilityContract.tokenMap(1, asset), erc20ABI, signer);
        await token.approve(stakingContract.address, amount);
        await stakingContract.stake(asset, amount, duration);
        updateBalances();
    });
}

async function lend(amount) {
    await confirmTransaction(`Lend ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await usdcContract.approve(lendingContract.address, amount);
        await lendingContract.lend(amount);
        updateBalances();
    });
}

async function borrow(amount) {
    await confirmTransaction(`Borrow ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await lendingContract.borrow(amount);
        updateBalances();
    });
}

async function repay(amount) {
    await confirmTransaction(`Repay ${ethers.utils.formatUnits(amount, 6)} USDC?`, async () => {
        await usdcContract.approve(lendingContract.address, amount);
        await lendingContract.repay(amount);
        updateBalances();
    });
}

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
        loadTransactionHistory();
        loadBetHistory();
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await provider.send("eth_requestAccounts", []);

    document.getElementById('signup-login').addEventListener('click', () => {
        document.getElementById('auth-modal').style.display = 'flex';
    });

    document.getElementById('signup-tab').addEventListener('click', () => {
        document.getElementById('signup-tab').classList.add('active');
        document.getElementById('login-tab').classList.remove('active');
        document.getElementById('signup-form').style.display = 'block';
        document.getElementById('login-form').style.display = 'none';
    });

    document.getElementById('login-tab').addEventListener('click', () => {
        document.getElementById('login-tab').classList.add('active');
        document.getElementById('signup-tab').classList.remove('active');
        document.getElementById('login-form').style.display = 'block';
        document.getElementById('signup-form').style.display = 'none';
    });

    document.getElementById('login-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('login-id').value;
        const password = document.getElementById('login-password').value;
        if (db.users[id]?.password === password) {
            currentUser = db.users[id].username;
            isLoggedIn = true;
            updateUI();
            document.getElementById('auth-modal').style.display = 'none';
        }
    });

    document.getElementById('signup-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('signup-email-phone').value;
        const username = document.getElementById('signup-username').value;
        db.users[email] = {
            username,
            password: document.getElementById('signup-password').value,
            assets: {},
            security: {
                q1: document.getElementById('security-question-1').value,
                a1: document.getElementById('security-answer-1').value,
                q2: document.getElementById('security-question-2').value,
                a2: document.getElementById('security-answer-2').value,
                q3: document.getElementById('security-question-3').value,
                a3: document.getElementById('security-answer-3').value
            }
        };
        currentUser = username;
        isLoggedIn = true;
        updateUI();
        document.getElementById('auth-modal').style.display = 'none';
    });

    document.getElementById('logout').addEventListener('click', () => {
        isLoggedIn = false;
        currentUser = null;
        updateUI();
    });

    document.getElementById('consume-zpe').addEventListener('click', async () => {
        const amount = document.getElementById('payment-amount').value;
        await confirmTransaction(`Consume ${amount || 1} $ZPE?`, async () => {
            const tx = await zpeContract.consumeForService(ethers.utils.parseUnits(amount || "1", 3));
            await tx.wait();
            await mediator.handleConsumption(1, "ZPE", ethers.utils.parseUnits(amount || "1", 3));
            updateBalances();
        });
    });

    document.getElementById('consume-zpw').addEventListener('click', async () => {
        const amount = document.getElementById('payment-amount').value;
        await confirmTransaction(`Consume ${amount || 1} $ZPW?`, async () => {
            const tx = await zpwContract.consumeForService(ethers.utils.parseUnits(amount || "1", 2));
            await tx.wait();
            await mediator.handleConsumption(1, "ZPW", ethers.utils.parseUnits(amount || "1", 2));
            updateBalances();
        });
    });

    document.getElementById('subscribe-zpp').addEventListener('click', async () => {
        await confirmTransaction(`Subscribe to $ZPP?`, async () => {
            const tx = await zppContract.subscribe();
            await tx.wait();
            await mediator.handleConsumption(1, "ZPP", 100);
            updateBalances();
        });
    });

    document.getElementById('add-device').addEventListener('click', async () => {
        const deviceId = document.getElementById('device-id').value;
        await confirmTransaction(`Add device ${deviceId}?`, async () => {
            const tx = await deviceContract.addDevice(deviceId);
            await tx.wait();
            loadDevices();
        });
    });

    document.getElementById('use-modal').addEventListener('click', async () => {
        const deviceId = document.getElementById('device-id').value;
        await confirmTransaction(`Use modal on ${deviceId}?`, async () => {
            const tx = await deviceContract.useModal(deviceId);
            await tx.wait();
            await mediator.handleModalPurchase(1 * 10**6);
            loadDevices();
            updateBalances();
        });
    });

    document.getElementById('bank-to-goate').addEventListener('click', async () => {
        alert("Bank to Goate Electric deposit initiated");
    });

    document.getElementById('goate-to-bank').addEventListener('click', async () => {
        alert("Goate Electric to Bank withdrawal initiated");
    });

    document.getElementById('watch-google-ad').addEventListener('click', () => watchAd("Google"));
    document.getElementById('watch-pi-ad').addEventListener('click', () => watchAd("Pi"));
    document.getElementById('watch-youtube-ad').addEventListener('click', () => watchAd("YouTube"));

    document.getElementById('free-play').addEventListener('click', () => startGame("FreePlay"));
    document.getElementById('reasonable').addEventListener('click', () => startGame("Reasonable"));
    document.getElementById('gambling').addEventListener('click', () => startGame("Gambling"));
    document.getElementById('rich').addEventListener('click', () => startGame("Rich"));

    document.getElementById('connect-plaid').addEventListener('click', () => plaidHandler.open());

    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            document.querySelectorAll('.page').forEach(page => page.classList.remove('active'));
            document.querySelector(link.getAttribute('href')).classList.add('active');
            if (link.getAttribute('href') === '#earn' && isLoggedIn) {
                loadTransactionHistory();
            } else if (link.getAttribute('href') === '#hometeambets' && isLoggedIn) {
                loadGames();
                loadBetHistory();
            } else if (link.getAttribute('href') === '#gerastyxopol' && isLoggedIn) {
                loadGame(await gerastyxOpolContract.sessionCount() - 1);
            } else if (link.getAttribute('href') === '#digital-stocks' && isLoggedIn) {
                loadStocks();
            } else if (link.getAttribute('href') === '#goate-staking' && isLoggedIn) {
                loadStaking();
            }
        });
    });

    const tokens = ["USDC", "ZPE", "ZPW", "ZPP", "GySt"];
    ["from-asset", "to-asset"].forEach(id => {
        const select = document.getElementById(id);
        tokens.forEach(token => select.innerHTML += `<option value="${token}">${token}</option>`);
    });

    document.getElementById('stock-search').addEventListener('input', (e) => {
        const search = e.target.value.toLowerCase();
        document.querySelectorAll('.stock-card').forEach(card => {
            card.style.display = card.querySelector('h3').textContent.toLowerCase().includes(search) ? 'block' : 'none';
        });
    });

    await initializeStocks(); // Initialize stocks on load
});
