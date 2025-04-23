const supportedAssets = ['USD', 'Pi', 'ZPE', 'ZPP', 'ZPW', 'GySt', 'GOATE', 'ZHV', 'SD'];
let currentUser = null;
let userPin = null;

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
            }
        })
        .catch((error) => {
            console.error("Pi Authentication failed:", error);
            alert("Authentication failed. Please try again.");
        });
};

// Update Balances
async function updateBalances() {
    for (const asset of supportedAssets) {
        const balance = await getBalance(asset); // Fetch from InstilledInteroperability
        document.getElementById(`${asset.toLowerCase()}-balance`).textContent = balance.toFixed(2);
    }
}

async function getBalance(asset) {
    // Placeholder: Fetch balance from InstilledInteroperability
    return Math.random() * 100; // Mock balance
}

// Navigation
function navigateTo(asset) {
    showFeatureModal(asset);
}

// Feature Modal
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
            <input type="text" id="asset-search" placeholder="Search crypto, stocks, fiat">
            ${supportedAssets.map(asset => `
                <div class="asset-tab">
                    <p>${asset}: $${getAssetPrice(asset)}</p>
                    <p>Balance: ${getBalance(asset).toFixed(2)}</p>
                    <button onclick="stakeAsset('${asset}')">Stake</button>
                    <button onclick="swapAsset('${asset}')">Swap</button>
                    <button onclick="transferAsset('${asset}')">Transfer</button>
                    <button onclick="lendAsset('${asset}')">Lend</button>
                    <button onclick="borrowAsset('${asset}')">Borrow</button>
                    ${['ZPE', 'ZPW', 'ZPP'].includes(asset) ? `<button onclick="consumeAsset('${asset}')">Consume</button>` : ''}
                    <div class="card-slider ${getCardStatus(asset) ? 'on' : 'off'}" onclick="toggleCard('${asset}')"></div>
                </div>
            `).join('')}
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
    } else if (feature === 'estates') {
        content.innerHTML = `
            <p>${currentUser}</p>
            <p>Pi Address: ${getPiAddress()}</p>
            <p>Total GerastyxPropertyNFT: ${getNFTCount()}</p>
            ${getNFTs().map(nft => `
                <div class="nft-tab">
                    <p>${nft.name}: $${nft.price}</p>
                    <p>Balance: ${nft.balance}</p>
                    <button onclick="sellNFT(${nft.id})">Sell</button>
                    <button onclick="auctionNFT(${nft.id})">Auction</button>
                    <button onclick="stakeNFT(${nft.id})">Stake</button>
                </div>
            `).join('')}
        `;
    } else {
        content.innerHTML = `<p>${feature} Page</p>`;
    }
    modal.style.display = 'flex';
}

function getPiAddress() { return "G..."; } // Fetch from InstilledInteroperability
function getAssetPrice(asset) { return Math.random() * 100; } // Fetch from USDMediator
function getCardStatus(asset) { return true; } // Fetch from TheLambduckCard
function getNFTCount() { return 0; } // Fetch from GerastyxPropertyNFT
function getNFTs() { return []; } // Fetch from GerastyxPropertyNFT

async function toggleCard(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        // Toggle card status via TheLambduckCard.sol
        console.log(`Toggled card for ${asset}`);
    } else {
        alert("Invalid PIN");
    }
}

async function validate() { console.log("Validate"); }
async function watchAd() {
    // Call AdWatch.sol
    console.log("Watch Ad");
}
async function deposit() {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log("Deposit");
    }
}
async function withdraw() {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log("Withdraw");
    }
}
async function stakeAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Stake ${asset}`);
    }
}
async function swapAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Swap ${asset}`);
    }
}
async function transferAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Transfer ${asset}`);
    }
}
async function lendAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Lend ${asset}`);
    }
}
async function borrowAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Borrow ${asset}`);
    }
}
async function consumeAsset(asset) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Consume ${asset}`);
    }
}
async function sellNFT(id) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Sell NFT ${id}`);
    }
}
async function auctionNFT(id) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Auction NFT ${id}`);
    }
}
async function stakeNFT(id) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Stake NFT ${id}`);
    }
}
async function startGame(game, mode) {
    const pin = prompt("Enter 4-digit PIN:");
    if (pin === userPin) {
        console.log(`Start ${game} in ${mode} mode`);
    }
}

function showSettings() {
    const modal = document.getElementById('feature-modal');
    const title = document.getElementById('feature-title');
    const content = document.getElementById('feature-content');
    title.textContent = "Settings";
    content.innerHTML = `
        <p>Username: ${currentUser}</p>
        <p>Pi Address: ${getPiAddress()}</p>
        <button onclick="connectBank()">Connect Bank</button>
        <button onclick="connectCard()">Connect Card</button>
        <p>TheLambduckCard: ${getCardInfo()}</p>
        <button onclick="changePin()">Change PIN</button>
    `;
    modal.style.display = 'flex';
}

function connectBank() { console.log("Connect Bank"); }
function connectCard() { console.log("Connect Card"); }
function getCardInfo() { return "**** **** **** 1234"; } // Fetch from TheLambduckCard
function changePin() {
    const newPin = prompt("Enter new 4-digit PIN:");
    if (/^\d{4}$/.test(newPin)) {
        userPin = newPin;
        alert("PIN updated");
    } else {
        alert("Invalid PIN");
    }
}

// Close Modal
document.querySelector('.close').onclick = () => {
    document.getElementById('feature-modal').style.display = 'none';
};
