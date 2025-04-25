const supportedAssets = ['USD', 'PI', 'ZPE', 'ZPP', 'ZPW', 'ZHV', 'GOATE', 'GySt', 'SD', 'ZGI', 'GP', 'zS'];
let currentUser = null;
let userPin = null;
let userPassword = null;
let sliders = {};

// Pi SDK Authentication
window.onload = async () => {
    await Pi.init({ version: "2.0" });
    Pi.authenticate()
        .then(async (auth) => {
            currentUser = auth.user.username;
            document.getElementById('settings').onclick = () => showSettings();
            await updateBalances();
            if (!userPin) {
                userPin = prompt("Create a 4-digit PIN:");
                while (!/^\d{4}$/.test(userPin)) {
                    userPin = prompt("Invalid PIN. Create a 4-digit PIN:");
                }
                userPassword = prompt("Create a password:");
                let confirmPassword = prompt("Confirm your password:");
                while (userPassword !== confirmPassword) {
                    userPassword = prompt("Passwords do not match. Create a password:");
                    confirmPassword = prompt("Confirm your password:");
                }
            }
        })
        .catch((error) => {
            console.error("Pi Authentication failed:", error);
            const modal = document.createElement('div');
            modal.className = 'modal';
            modal.innerHTML = `
                <div class="modal-content">
                    <p>Authentication failed. Please allow access to continue.</p>
                    <button onclick="window.location.reload()">Retry</button>
                    <p class="pi-signup">Don't have a Pi Account? <a href="https://minepi.com/cj03nes" target="_blank">Sign up with referral code: cj03nes</a></p>
                </div>
            `;
            document.body.appendChild(modal);
            modal.style.display = 'flex';
        });
};

// Update Balances
async function updateBalances() {
    for (const asset of supportedAssets) {
        const balance = await getBalance(asset);
        document.getElementById(`${asset.toLowerCase()}-balance`).textContent = balance.toFixed(2);
    }
}

async function getBalance(asset) {
    // Fetch balance from InstilledInteroperability
    return Math.random() * 100; // Mock
}

function navigateTo(asset) {
    showFeatureModal(asset);
}

function toggleSlider(asset) {
    const slider = document.querySelector(`.slider[onclick="toggleSlider('${asset}')"]`);
    const isOn = slider.classList.contains('on');
    slider.classList.toggle('on', !isOn);
    slider.classList.toggle('off', isOn);
    sliders[asset] = !isOn;
    // Update PayWithCrypto.sol
}

function showFeatureModal(feature) {
    const modal = document.getElementById('feature-modal');
    const title = document.getElementById('feature-title');
    const content = document.getElementById('feature-content');
    title.textContent = feature.charAt(0).toUpperCase() + feature.slice(1);

    if (feature === 'wallet') {
        content.innerHTML = `
            <button onclick="validate()">Validate</button>
            <button onclick="watchAd()">Watch Ad</button>
            <p>${currentUser}</p>
            <p>Pi Address: ${getPiAddress()}</p>
            <button onclick="deposit()">Deposit</button>
            <button onclick="withdraw()">Withdraw</button>
            <select id="sort-assets" onchange="sortAssets()">
                <option value="balance-desc">Balance (Greatest to Least)</option>
                <option value="balance-asc">Balance (Least to Greatest)</option>
                <option value="name-asc">Name (A-Z)</option>
                <option value="name-desc">Name (Z-A)</option>
                <option value="fiat-crypto-stocks">Fiat-Crypto-Stocks</option>
                <option value="fiat-stocks-crypto">Fiat-Stocks-Crypto</option>
                <option value="crypto-fiat-stocks">Crypto-Fiat-Stocks</option>
                <option value="crypto-stocks-fiat">Crypto-Stocks-Fiat</option>
                <option value="stocks-crypto-fiat">Stocks-Crypto-Fiat</option>
                <option value="stocks-fiat-crypto">Stocks-Fiat-Crypto</option>
            </select>
            <input type="text" id="asset-search" placeholder="Search crypto, stocks, fiat">
            <div id="assets-list">
                ${supportedAssets.map(asset => `
                    <div class="asset-tab">
                        <img src="${asset.toLowerCase()}_logo.png" class="token-logo" alt="${asset} Logo">
                        <p>${asset}: $${getAssetPrice(asset)}</p>
                        <p>Balance: ${getBalance(asset).toFixed(2)}</p>
                        <p>Staking Balance: ${getStakingBalance(asset).toFixed(2)} USD</p>
                        <p>APR: ${getAPR(asset)}%</p>
                        <button onclick="stakeAsset('${asset}')">Stake</button>
                        <button onclick="swapAsset('${asset}')">Swap</button>
                        <button onclick="transferAsset('${asset}')">Transfer</button>
                        <button onclick="lendAsset('${asset}')">Lend</button>
                        <button onclick="borrowAsset('${asset}')">Borrow</button>
                        ${['ZPE', 'ZPW', 'ZPP'].includes(asset) ? `<button onclick="consumeAsset('${asset}')">Consume</button>` : ''}
                        ${asset !== 'USD' ? `<div class="card-slider ${sliders[asset] !== false ? 'on' : 'off'}" onclick="toggleCard('${asset}')"></div>` : ''}
                    </div>
                `).join('')}
            </div>
            <h3>Transaction History</h3>
            <div id="transaction-history"></div>
        `;
    } else if (feature === 'gerastyx') {
        content.innerHTML = `
            <button onclick="navigateTo('hometeambets')">HomeTeamBets</button>
            <h3>Gerastyx Opol Mode</h3>
            <button onclick="startGame('gerastyxopol', 'Free')">Free</button>
            <button onclick="startGame('gerastyxopol', 'OneDollar')">Civilian</button>
            <button onclick="startGame('gerastyxopol', 'TwentyDollar')">Banker</button>
            <button onclick="startGame('gerastyxopol', 'HundredDollar')">Monopoly</button>
            <button onclick="navigateTo('estates')">GerastyxOpol Estates</button>
            <button onclick="navigateTo('streaming')">Watch Movies, TV, & Stream</button>
            <button onclick="navigateTo('circumference')">Circumference of Pi</button>
            <h3>Spades Mode</h3>
            <button onclick="startGame('spades', 'Free')">Free</button>
            <button onclick="startGame('spades', 'OneDollar')">$1</button>
            <button onclick="startGame('spades', 'TwentyDollar')">$20</button>
            <button onclick="startGame('spades', 'HundredDollar')">$100</button>
            <h3>Pity Pat Mode</h3>
            <button onclick="startGame('pitypat', 'Free')">Free</button>
            <button onclick="startGame('pitypat', 'OneDollar')">$1</button>
            <button onclick="startGame('pitypat', 'TwentyDollar')">$20</button>
            <button onclick="startGame('pitypat', 'HundredDollar')">$100</button>
            <h3>War Mode</h3>
            <button onclick="startGame('war', 'Free')">Free</button>
            <button onclick="startGame('war', 'OneDollar')">$1</button>
            <button onclick="startGame('war', 'TwentyDollar')">$20</button>
            <button onclick="startGame('war', 'HundredDollar')">$100</button>
        `;
    } else if (feature === 'streaming') {
        content.innerHTML = `
            <input type="text" id="streaming-search" placeholder="Search movies, shows, categories">
            <div class="holographic-player">
                <video id="holographic-video" controls></video>
                <div class="holographic-controls">
                    <button onclick="playVideo()">Play</button>
                    <button onclick="pauseVideo()">Pause</button>
                    <button onclick="rewindVideo()">Rewind</button>
                    <button onclick="fastForwardVideo()">Fast Forward</button>
                    <select id="subtitles">
                        <option value="en">English</option>
                        <option value="es">Spanish</option>
                    </select>
                    <input type="range" id="volume" min="0" max="100" value="50" onchange="setVolume()">
                </div>
                <div class="holographic-view-slider on" onclick="toggleHolographicView()"></div>
            </div>
        `;
        const video = document.getElementById('holographic-video');
        video.ondisconnect = () => {
            console.log(`Disconnected at timestamp: ${video.currentTime}`);
        };
    } else if (feature === 'circumference') {
        content.innerHTML = `
            <button onclick="deposit()">Deposit</button>
            <button onclick="withdraw()">Withdraw</button>
            <button onclick="buyAndSwap()">Buy & Swap</button>
            <button onclick="transfer()">Transfer</button>
            <button onclick="stake()">Stake</button>
            <button onclick="consumeZPEorZPP()">Consume Zeropoint</button>
            <div class="balances">
                <div class="balance">
                    <img src="pi_logo.png" class="token-logo" alt="$PI Logo">
                    $PI: <span id="pi-circumference-balance">0</span>
                    <p>Address: ${getPiAddress()}</p>
                </div>
                <div class="balance">
                    <img src="xlm_logo.png" class="token-logo" alt="$XLM Logo">
                    $XLM: <span id="xlm-circumference-balance">0</span>
                    <p>Address: ${getXLMAddress()}</p>
                </div>
                <div class="balance">
                    <img src="usdc_logo.png" class="token-logo" alt="$USDC Logo">
                    $USDC: <span id="usdc-circumference-balance">0</span>
                    <p>Address: ${getUSDCAddress()}</p>
                </div>
                <div class="balance">
                    <img src="btc_logo.png" class="token-logo" alt="$BTC Logo">
                    $BTC: <span id="btc-circumference-balance">0</span>
                    <p>Address: ${getBTCAddress()}</p>
                </div>
                <div class="balance">
                    <img src="zpe_logo.png" class="token-logo" alt="$ZPE Logo">
                    $ZPE: <span id="zpe-circumference-balance">0</span>
                    <p>Address: ${getZPEAddress()}</p>
                </div>
                <div class="balance">
                    <img src="zpp_logo.png" class="token-logo" alt="$ZPP Logo">
                    $ZPP: <span id="zpp-circumference-balance">0</span>
                    <p>Address: ${getZPPAddress()}</p>
                </div>
            </div>
        `;
    } else {
        content.innerHTML = `<p>${feature} Page</p>`;
    }
    modal.style.display = 'flex';
}

function getPiAddress() { return "G..."; }
function getXLMAddress() { return "G..."; }
function getUSDCAddress() { return "0x..."; }
function getBTCAddress() { return "3..."; }
function getZPEAddress() { return "0x..."; }
function getZPPAddress() { return "0x..."; }
function getAssetPrice(asset) { return Math.random() * 100; }
function getStakingBalance(asset) { return Math.random() * 50; }
function getAPR(asset) { return 10; } // Mock

function sortAssets() {
    const sortOption = document.getElementById('sort-assets').value;
    let assets = [...supportedAssets];
    if (sortOption === 'balance-desc') {
        assets.sort((a, b) => getBalance(b) - getBalance(a));
    } else if (sortOption === 'balance-asc') {
        assets.sort((a, b) => getBalance(a) - getBalance(b));
    } else if (sortOption === 'name-asc') {
        assets.sort();
    } else if (sortOption === 'name-desc') {
        assets.sort().reverse();
    } else {
        const fiat = ['USD'];
        const crypto = ['PI', 'ZPE', 'ZPP', 'ZPW', 'ZHV', 'GOATE', 'GySt', 'SD', 'ZGI', 'GP'];
        const stocks = ['zS'];
        let order = [];
        if (sortOption === 'fiat-crypto-stocks') order = [...fiat, ...crypto, ...stocks];
        else if (sortOption === 'fiat-stocks-crypto') order = [...fiat, ...stocks, ...crypto];
        else if (sortOption === 'crypto-fiat-stocks') order = [...crypto, ...fiat, ...stocks];
        else if (sortOption === 'crypto-stocks-fiat') order = [...crypto, ...stocks, ...fiat];
        else if (sortOption === 'stocks-crypto-fiat') order = [...stocks, ...crypto, ...fiat];
        else if (sortOption === 'stocks-fiat-crypto') order = [...stocks, ...fiat, ...crypto];
        assets = order;
    }
    const assetsList = document.getElementById('assets-list');
    assetsList.innerHTML = assets.map(asset => `
        <div class="asset-tab">
            <img src="${asset.toLowerCase()}_logo.png" class="token-logo" alt="${asset} Logo">
            <p>${asset}: $${getAssetPrice(asset)}</p>
            <p>Balance: ${getBalance(asset).toFixed(2)}</p>
            <p>Staking Balance: ${getStakingBalance(asset).toFixed(2)} USD</p>
            <p>APR: ${getAPR(asset)}%</p>
            <button onclick="stakeAsset('${asset}')">Stake</button>
            <button onclick="swapAsset('${asset}')">Swap</button>
            <button onclick="transferAsset('${asset}')">Transfer</button>
            <button onclick="lendAsset('${asset}')">Lend</button>
            <button onclick="borrowAsset('${asset}')">Borrow</button>
            ${['ZPE', 'ZPW', 'ZPP'].includes(asset) ? `<button onclick="consumeAsset('${asset}')">Consume</button>` : ''}
            ${asset !== 'USD' ? `<div class="card-slider ${sliders[asset] !== false ? 'on' : 'off'}" onclick="toggleCard('${asset}')"></div>` : ''}
        </div>
    `).join('');
}

function playVideo() { document.getElementById('holographic-video').play(); }
function pauseVideo() { document.getElementById('holographic-video').pause(); }
function rewindVideo() { document.getElementById('holographic-video').currentTime -= 30; }
function fastForwardVideo() { document.getElementById('holographic-video').currentTime += 30; }
function setVolume() {
    const video = document.getElementById('holographic-video');
    video.volume = document.getElementById('volume').value / 100;
}
function toggleHolographicView() {
    const slider = document.querySelector('.holographic-view-slider');
    slider.classList.toggle('on');
    // Toggle holographic projection (handled by Unreal Engine)
}

// Other functions (deposit, withdraw, etc.) remain as previously implemented
