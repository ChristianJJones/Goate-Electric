const supportedAssets = ['USD', 'PI', 'ZPE', 'ZPP', 'ZPW', 'ZHV', 'GOATE', 'GySt', 'SD', 'ZGI', 'GP', 'zS'];
let currentUser = null;
let userPin = null;
let userPassword = null;
let userData = {
    piAddress: null,
    email: null,
    appleId: null,
    bank: { accountNumber: null, routingNumber: null },
    card: { number: null, expiration: null, cvc: null },
    phoneNumber: null,
    ssn: null,
    username: null,
    address: null
};
let devices = [];
let isNewDevice = false;

// Web3 and cross-chain variables
let provider;
let signer;
let energyManager;
let tokenManager;
let entertainmentManager;
let financeManager;
let usdMediator;
let instilledInteroperability;

// Supported chains
const supportedChains = ['Stellar', 'Binance', 'Ethereum', 'Arbitrum', 'Pi Network', 'Cronos'];
let activeChain = 'Stellar'; // Default chain
let chainProviders = {};

// Mock Instilled Interoperability node rewards (100% allocated as revenue)
let nodeRewards = 0;
function allocateNodeRewards() {
    console.log(`Instilled Interoperability Node Rewards: ${nodeRewards} allocated as revenue (100%)`);
    // In a real implementation, this would distribute rewards to a revenue pool
}

window.onload = async () => {
    await Pi.init({ version: "2.0" });

    document.getElementById('login').onclick = showLoginModal;
    document.getElementById('connect-device').onclick = connectDevice;
    document.getElementById('settings').onclick = showSettings;
    document.getElementById('sign-in-pi').onclick = signInWithPi;
    document.getElementById('sign-in-google').onclick = signInWithGoogle;
    document.getElementById('sign-in-apple').onclick = signInWithApple;

    await initWeb3WithInteroperability();
};

async function initWeb3WithInteroperability() {
    if (!window.ethereum) {
        alert('Please install MetaMask to use this feature.');
        return;
    }

    // Initialize Instilled Interoperability nodes (mocked for now)
    instilledInteroperability = {
        connectToChain: async (chain) => {
            console.log(`Instilled Interoperability: Connecting to ${chain}...`);
            // Simulate node connection providing energy, Wi-Fi, computational energy, data storage, etc.
            nodeRewards += Math.random() * 10; // Simulate rewards generation
            allocateNodeRewards();
            return true;
        },
        disconnectFromChain: async (chain) => {
            console.log(`Instilled Interoperability: Disconnecting from ${chain}...`);
            // Nodes remain connected in the back-end for resource provision
            nodeRewards += Math.random() * 5; // Continue generating rewards
            allocateNodeRewards();
            return true;
        }
    };

    // Initialize USDMediator for cross-chain transactions (mocked for now)
    usdMediator = {
        mediateTransaction: async (fromChain, toChain, asset, amount) => {
            console.log(`USDMediator: Mediating ${amount} ${asset} from ${fromChain} to ${toChain}`);
            // Simulate asset conversion (e.g., USD to chain-native token)
            return amount; // Return mediated amount
        }
    };

    // Initialize providers for all supported chains
    for (const chain of supportedChains) {
        await instilledInteroperability.connectToChain(chain);
        if (chain === 'Ethereum' || chain === 'Arbitrum') {
            // Use MetaMask for Ethereum-compatible chains
            chainProviders[chain] = new ethers.providers.Web3Provider(window.ethereum);
        } else if (chain === 'Binance') {
            // Mock Binance Smart Chain provider
            chainProviders[chain] = new ethers.providers.JsonRpcProvider('https://bsc-dataseed.binance.org/');
        } else if (chain === 'Cronos') {
            // Mock Cronos provider
            chainProviders[chain] = new ethers.providers.JsonRpcProvider('https://evm.cronos.org/');
        } else if (chain === 'Pi Network') {
            // Mock Pi Network provider
            chainProviders[chain] = { provider: 'Pi Network SDK', custom: true };
        } else if (chain === 'Stellar') {
            // Mock Stellar provider
            chainProviders[chain] = { provider: 'Stellar SDK', custom: true };
        }
    }

    // Set default active chain (Stellar)
    await setActiveChain('Stellar');
}

async function setActiveChain(chain) {
    if (!supportedChains.includes(chain)) {
        alert('Unsupported chain selected.');
        return;
    }

    // Disconnect from the previous chain (front-end only, nodes remain connected in back-end)
    if (activeChain !== chain) {
        await instilledInteroperability.disconnectFromChain(activeChain);
    }

    activeChain = chain;

    // Initialize provider and signer for the active chain
    if (chain === 'Ethereum' || chain === 'Arbitrum' || chain === 'Binance' || chain === 'Cronos') {
        provider = chainProviders[chain];
        await provider.send("eth_requestAccounts", []);
        signer = provider.getSigner();

        // Initialize contracts (replace with actual deployed addresses)
        const energyManagerAddress = "YOUR_ENERGY_MANAGER_ADDRESS";
        const tokenManagerAddress = "YOUR_TOKEN_MANAGER_ADDRESS";
        const entertainmentManagerAddress = "YOUR_ENTERTAINMENT_MANAGER_ADDRESS";
        const financeManagerAddress = "YOUR_FINANCE_MANAGER_ADDRESS";

        energyManager = new ethers.Contract(energyManagerAddress, EnergyManagerABI, signer);
        tokenManager = new ethers.Contract(tokenManagerAddress, TokenManagerABI, signer);
        entertainmentManager = new ethers.Contract(entertainmentManagerAddress, EntertainmentManagerABI, signer);
        financeManager = new ethers.Contract(financeManagerAddress, FinanceManagerABI, signer);
    } else if (chain === 'Pi Network') {
        provider = chainProviders[chain];
        signer = null; // Pi Network uses a different authentication mechanism
    } else if (chain === 'Stellar') {
        provider = chainProviders[chain];
        signer = null; // Stellar uses a different signing mechanism
    }

    console.log(`Active chain set to ${activeChain}`);
}

function showLoginModal() {
    if (currentUser) {
        alert('Already logged in as ' + userData.username);
        return;
    }
    document.getElementById('login-modal').style.display = 'flex';
}

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
}

async function signInWithPi() {
    try {
        const auth = await Pi.authenticate();
        document.getElementById('pi-auth').style.display = 'block';
        userData.piAddress = auth.user.username;
    } catch (error) {
        console.error("Pi Authentication failed:", error);
        alert('Pi Authentication failed. Try again.');
    }
}

function acceptPiAuth() {
    completeLogin('pi', userData.piAddress);
}

function declinePiAuth() {
    document.getElementById('pi-auth').style.display = 'none';
}

function createPiAccount() {
    window.open('https://minepi.com/cj03nes', '_blank');
}

function signInWithGoogle() {
    userData.email = prompt('Enter Google email:');
    completeLogin('google', userData.email);
}

function signInWithApple() {
    userData.appleId = prompt('Enter Apple ID:');
    completeLogin('apple', userData.appleId);
}

async function completeLogin(method, identifier) {
    if (isNewDevice || !localStorage.getItem('deviceId')) {
        const password = prompt('Enter password for new device/IP:');
        if (!await verifyPassword(identifier, password)) {
            alert('Invalid password.');
            return;
        }
    }

    currentUser = identifier;
    userData.username = identifier.split('@')[0] || identifier;
    document.getElementById('login').textContent = userData.username;

    if (!userPin) {
        userPin = prompt('Create a 4-digit PIN:');
        while (!/^\d{4}$/.test(userPin)) {
            userPin = prompt('Invalid PIN. Create a 4-digit PIN:');
        }
        userPassword = prompt('Create a password:');
        let confirmPassword = prompt('Confirm your password:');
        while (userPassword !== confirmPassword) {
            userPassword = prompt('Passwords do not match. Create a password:');
            confirmPassword = prompt('Confirm your password:');
        }
    }

    if (!userData.bank.accountNumber) {
        userData.bank.accountNumber = generateBankAccountNumber();
        userData.bank.routingNumber = generateRoutingNumber();
    }
    if (!userData.card.number) {
        userData.card = generateCardDetails();
    }

    if (!userData.phoneNumber) {
        userData.phoneNumber = prompt('Enter phone number:');
    }
    if (!userData.ssn) {
        userData.ssn = prompt('Enter SSN (optional):');
    }

    await updateBalances();
    closeModal('login-modal');
}

async function verifyPassword(identifier, password) {
    return password === userPassword;
}

function generateBankAccountNumber() {
    return 'XXXX' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
}

function generateRoutingNumber() {
    return '0' + Math.floor(Math.random() * 100000000).toString().padStart(8, '0');
}

function generateCardDetails() {
    const number = '4' + Math.floor(Math.random() * 10**15).toString().padStart(15, '0');
    const expiration = new Date();
    expiration.setFullYear(expiration.getFullYear() + 20);
    const expStr = `${expiration.getMonth() + 1}/${expiration.getFullYear() % 100}`;
    const cvc = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return { number, expiration: expStr, cvc };
}

async function updateBalances() {
    if (!currentUser) return;
    for (const asset of supportedAssets) {
        try {
            let balance;
            if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
                // Mock balance fetch for non-EVM chains
                balance = Math.random() * 100;
            } else {
                balance = await tokenManager.getBalance(asset);
                balance = ethers.utils.formatUnits(balance, 18);
            }
            document.getElementById(`${asset.toLowerCase()}-balance`)?.textContent = balance.toFixed(2);
        } catch (error) {
            console.error(`Error fetching balance for ${asset}:`, error);
        }
    }
}

async function connectDevice() {
    if (!currentUser) {
        alert('Please login first.');
        return;
    }

    const deviceId = localStorage.getItem('deviceId') || generateDeviceId();
    localStorage.setItem('deviceId', deviceId);

    try {
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Registering device ${deviceId} on ${activeChain}`);
        } else {
            await energyManager.registerDevice(deviceId);
        }
    } catch (error) {
        console.error('Error registering device:', error);
        alert('Failed to register device.');
        return;
    }

    document.getElementById('connect-device').textContent = 'deviceConnected';
    setTimeout(() => {
        document.getElementById('connect-device').textContent = 'Manage Devices';
        document.getElementById('connect-device').onclick = showManageDevices;
    }, 2000);

    devices.push({ id: deviceId, name: 'Device ' + devices.length + 1, chain: activeChain });
}

function generateDeviceId() {
    return 'DEV' + Math.random().toString(36).substr(2, 9);
}

function showManageDevices() {
    const modal = document.getElementById('feature-modal');
    const title = document.getElementById('feature-title');
    const content = document.getElementById('feature-content');

    title.textContent = 'Manage Devices';
    content.innerHTML = `
        <div class="devices">
            ${devices.map(device => `
                <div class="device">
                    <p>Device Name: ${device.name}</p>
                    <p>IMEI: ${device.id}</p>
                    <p>Active Chain: ${device.chain}</p>
                    <div class="chain-selector">
                        <label>Select Chain:</label>
                        ${supportedChains.map(chain => `
                            <div class="chain-option">
                                <span>${chain}</span>
                                <label class="switch">
                                    <input type="checkbox" id="chain-${chain}-${device.id}" ${device.chain === chain ? 'checked' : ''} onchange="changeChain('${device.id}', '${chain}')">
                                    <span class="slider ${device.chain === chain ? 'active' : ''}"></span>
                                </label>
                            </div>
                        `).join('')}
                    </div>
                    <input type="number" placeholder="Input $ZPE" id="zpe-${device.id}">
                    <button onclick="consumeZPE('${device.id}')">Consume Zeropoint</button>
                    <input type="number" placeholder="Input $ZPWP" id="zpwp-${device.id}">
                    <button onclick="consumeZPWP('${device.id}')">Consume Zeropoint Phone Service</button>
                    <input type="number" placeholder="Input $ZPW" id="zpw-${device.id}">
                    <button onclick="consumeToDevice('ZPW', '${device.id}')">Consume To Device</button>
                    <input type="number" placeholder="Input $ZPE" id="zpe-device-${device.id}">
                    <button onclick="consumeToDevice('ZPE', '${device.id}')">Consume To Device</button>
                    <input type="number" placeholder="Input $ZPE" id="zpe-insurance-${device.id}">
                    <button onclick="addToInsurance('${device.id}')">Add to Insurance Balance</button>
                    <label>Insure Connected Item: <input type="checkbox" id="insure-${device.id}" disabled></label>
                    <button onclick="removeDevice('${device.id}')">Remove Device</button>
                </div>
            `).join('')}
            <button class="add-device" onclick="addDevice()">+</button>
            <button onclick="manualInputIMEI()">Manual Input IMEI</button>
            <button onclick="scanDevice()">Scan</button>
        </div>
    `;
    modal.style.display = 'flex';
}

async function changeChain(deviceId, newChain) {
    const device = devices.find(d => d.id === deviceId);
    if (!device) return;

    if (device.chain === newChain) return; // Already on this chain

    const pin = prompt(`Enter 4-digit PIN to switch to ${newChain}:`);
    if (pin !== userPin) {
        alert('Invalid PIN.');
        document.getElementById(`chain-${newChain}-${deviceId}`).checked = false;
        document.getElementById(`chain-${device.chain}-${deviceId}`).checked = true;
        return;
    }

    // Update device chain
    device.chain = newChain;
    await setActiveChain(newChain);

    // Update UI to reflect the active chain
    supportedChains.forEach(chain => {
        const slider = document.querySelector(`#chain-${chain}-${deviceId} + .slider`);
        if (chain === newChain) {
            slider.classList.add('active');
        } else {
            slider.classList.remove('active');
            document.getElementById(`chain-${chain}-${deviceId}`).checked = false;
        }
    });

    showManageDevices();
}

async function consumeZPE(deviceId) {
    const amount = document.getElementById(`zpe-${deviceId}`).value;
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, 'ZPE', amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Consuming ${mediatedAmount} ZPE on ${activeChain}`);
        } else {
            const tx = await energyManager.consumeEnergy(deviceId, ethers.utils.parseUnits(mediatedAmount, 0));
            await tx.wait();
            alert('ZPE consumed successfully!');
        }
    } catch (error) {
        console.error(error);
        alert('Failed to consume ZPE.');
    }
}

async function consumeZPWP(deviceId) {
    const amount = document.getElementById(`zpwp-${deviceId}`).value;
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, 'ZPWP', amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Consuming ${mediatedAmount} ZPWP on ${activeChain}`);
        } else {
            const tx = await energyManager.consumeEnergy(deviceId, ethers.utils.parseUnits(mediatedAmount, 0));
            await tx.wait();
            alert('ZPWP consumed successfully!');
        }
    } catch (error) {
        console.error(error);
        alert('Failed to consume ZPWP.');
    }
}

async function consumeToDevice(asset, deviceId) {
    const amount = document.getElementById(`${asset.toLowerCase()}-device-${deviceId}`).value;
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Consuming ${mediatedAmount} ${asset} on ${activeChain}`);
        } else {
            const tx = await energyManager.consumeEnergy(deviceId, ethers.utils.parseUnits(mediatedAmount, 0));
            await tx.wait();
            alert(`${asset} consumed successfully!`);
        }
    } catch (error) {
        console.error(error);
        alert(`Failed to consume ${asset}.`);
    }
}

async function addToInsurance(deviceId) {
    const amount = document.getElementById(`zpe-insurance-${deviceId}`).value;
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, 'ZPE', amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Adding ${mediatedAmount} ZPE to insurance on ${activeChain}`);
        } else {
            const tx = await tokenManager.addToInsurance(deviceId, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            document.getElementById(`insure-${deviceId}`).checked = true;
            alert('Added to insurance balance successfully!');
        }
    } catch (error) {
        console.error(error);
        alert('Failed to add to insurance balance.');
    }
}

function removeDevice(deviceId) {
    devices = devices.filter(d => d.id !== deviceId);
    showManageDevices();
}

function addDevice() {
    const name = prompt('Enter device name:');
    const id = generateDeviceId();
    devices.push({ id, name, chain: activeChain });
    showManageDevices();
}

function manualInputIMEI() {
    const imei = prompt('Enter IMEI:');
    devices.push({ id: imei, name: 'Manual Device', chain: activeChain });
    showManageDevices();
}

function scanDevice() {
    alert('Scanning device...');
    devices.push({ id: generateDeviceId(), name: 'Scanned Device', chain: activeChain });
    showManageDevices();
}

function showSettings() {
    if (!currentUser) {
        alert('Please login first.');
        return;
    }

    const modal = document.getElementById('feature-modal');
    const title = document.getElementById('feature-title');
    const content = document.getElementById('feature-content');

    title.textContent = 'Settings';
    content.innerHTML = `
        <div class="settings">
            <h3>Account Settings</h3>
            <p>THE LAMBDUCK INC Monopolies Bank</p>
            <p>TheLambduckCard: ${userData.card.number} Exp: ${userData.card.expiration} CVC: ${userData.card.cvc}</p>
            <p>Account Type: Checking</p>
            <p>Account Number: ${userData.bank.accountNumber}</p>
            <p>Routing Number: ${userData.bank.routingNumber}</p>
            <p>Name: ${userData.username}</p>
            <p>SSN: ${userData.ssn ? '****-**-****' : 'Not Provided'}</p>
            <button onclick="connectBank()">Connect Bank</button>
            <button onclick="updateBank()">Update Bank</button>
            <button onclick="connectCard()">Connect Card</button>
            <button onclick="updateCard()">Update Card</button>
            <button onclick="updateUsername()">Update Username</button>
            <button onclick="updatePassword()">Update Password</button>
            <button onclick="updatePin()">Update Pin Code</button>
            <button onclick="updateEmail()">Update Email Address</button>
            <button onclick="updatePhone()">Update Phone Number</button>
            <button onclick="updateAddress()">Update Address</button>
            <button onclick="updateLambduckCard()">Update TheLambduckCard</button>
        </div>
    `;
    modal.style.display = 'flex';
}

function connectBank() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.bank.accountNumber = generateBankAccountNumber();
    userData.bank.routingNumber = generateRoutingNumber();
    showSettings();
}

function updateBank() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    const content = document.getElementById('feature-content');
    content.innerHTML = `
        <button onclick="removeBank()">Remove Bank</button>
        <button onclick="replaceBank()">Replace Bank</button>
    `;
}

function removeBank() {
    userData.bank = { accountNumber: null, routingNumber: null };
    showSettings();
}

function replaceBank() {
    userData.bank.accountNumber = generateBankAccountNumber();
    userData.bank.routingNumber = generateRoutingNumber();
    showSettings();
}

function connectCard() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.card = generateCardDetails();
    showSettings();
}

function updateCard() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.card = generateCardDetails();
    showSettings();
}

function updateUsername() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.username = prompt('Enter new username:');
    showSettings();
}

function updatePassword() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userPassword = prompt('Enter new password:');
    let confirmPassword = prompt('Confirm new password:');
    while (userPassword !== confirmPassword) {
        userPassword = prompt('Passwords do not match. Enter new password:');
        confirmPassword = prompt('Confirm new password:');
    }
    showSettings();
}

function updatePin() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userPin = prompt('Enter new 4-digit PIN:');
    while (!/^\d{4}$/.test(userPin)) {
        userPin = prompt('Invalid PIN. Enter new 4-digit PIN:');
    }
    showSettings();
}

function updateEmail() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.email = prompt('Enter new email:');
    showSettings();
}

function updatePhone() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.phoneNumber = prompt('Enter new phone number:');
    showSettings();
}

function updateAddress() {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    userData.address = prompt('Enter new address:');
    showSettings();
}

function updateLambduckCard() {
    const pin = prompt('Enter 4-digit PIN or password:');
    if (pin !== userPin && pin !== userPassword) {
        alert('Invalid PIN or password.');
        return;
    }
    userData.card = generateCardDetails();
    const newPin = prompt('Create new 4-digit PIN:');
    while (!/^\d{4}$/.test(newPin)) {
        newPin = prompt('Invalid PIN. Create new 4-digit PIN:');
    }
    const confirmPin = prompt('Confirm new 4-digit PIN:');
    if (newPin === confirmPin) {
        userPin = newPin;
    } else {
        alert('PINs do not match.');
    }
    showSettings();
}

function navigateTo(service) {
    if (!currentUser) {
        alert('Please login first.');
        return;
    }

    const modal = document.getElementById('feature-modal');
    const title = document.getElementById('feature-title');
    const content = document.getElementById('feature-content');

    if (service === 'goate-electric') {
        title.textContent = 'Goate Electric';
        content.innerHTML = `
            <div class="balances">
                ${supportedAssets.map(asset => `
                    <div class="balance">
                        <img src="${asset.toLowerCase()}_logo.png" class="token-logo" alt="${asset} Logo">
                        ${asset}: <span id="${asset.toLowerCase()}-balance">0</span>
                        <p>USD: $${(Math.random() * 100).toFixed(2)}</p>
                        ${asset === 'ZGI' ? `<label>Insurance: <input type="checkbox" id="zgi-toggle" disabled></label>` : ''}
                    </div>
                `).join('')}
            </div>
            <button onclick="deposit()">Deposit</button>
            <button onclick="withdraw()">Withdraw</button>
            <button onclick="swap()">Swap</button>
            <button onclick="consume()">Consume</button>
            <button onclick="transfer()">Transfer</button>
            <button onclick="stake()">Stake</button>
            <h3>Transaction History</h3>
            <div id="transaction-history"></div>
        `;
        updateBalances();
    } else if (service === 'gerastyx') {
        title.textContent = 'Gerastyx';
        content.innerHTML = `
            <div class="balances">
                <div class="balance">GySt: <span id="gyst-balance">0</span></div>
                <div class="balance">GOATE: <span id="goate-balance">0</span></div>
            </div>
            <div class="games">
                <button onclick="playGame('HomeTeamBets')">HomeTeamBets</button>
                <button onclick="playGame('Goate ScratchOffs')">Goate ScratchOffs</button>
                <button onclick="playGame('Goate Spades')">Goate Spades</button>
                <button onclick="playGame('GerastyxOpol')">GerastyxOpol</button>
                <button onclick="playGame('Goat War')">Goat War</button>
                <button onclick="playGame('Goate Pity Pat')">Goate Pity Pat</button>
                <button onclick="watchAds()">Watch Ads</button>
                <button onclick="zeropointHolographicView()">ZeropointHolographicView</button>
                <button onclick="validationPortal()">Validation Portal</button>
            </div>
        `;
        updateBalances();
    } else if (service === 'goatepig') {
        title.textContent = 'GoatePig';
        content.innerHTML = `
            <div class="goatepig">
                <div class="section">
                    <h3>GoatePig</h3>
                    <p>$GP Balance: <span id="gp-balance">0</span></p>
                    <p>$GP Address: ${userData.piAddress || 'N/A'}</p>
                </div>
                <div class="section">
                    <h3>Circumference of Pi</h3>
                    <p>$PiR2 Balance: <span id="pir2-balance">0</span></p>
                    <p>$PiR2 Address: ${userData.piAddress || 'N/A'}</p>
                </div>
                <select id="sort-assets">
                    <option value="balance-desc">Highest Balance</option>
                    <option value="balance-asc">Lowest Balance</option>
                    <option value="name-asc">Alphabetical (A-Z)</option>
                    <option value="name-desc">Reverse Alphabetical (Z-A)</option>
                    <option value="crypto-stocks">Crypto - Stocks</option>
                    <option value="stocks-crypto">Stocks - Crypto</option>
                </select>
                <input type="text" id="asset-search" placeholder="Search assets">
                <div id="assets-list">
                    ${supportedAssets.map(asset => `
                        <div class="asset-card">
                            <p>Token: ${asset}</p>
                            <p>Balance: <span id="${asset.toLowerCase()}-balance">0</span></p>
                            <input type="number" placeholder="Stake Amount" id="stake-${asset}">
                            <button onclick="stakeAsset('${asset}')">Stake</button>
                            <input type="number" placeholder="Farm Amount" id="farm-${asset}">
                            <button onclick="farmAsset('${asset}')">Farm</button>
                            <input type="number" placeholder="Liquidity Amount" id="lp-${asset}">
                            <button onclick="provideLiquidity('${asset}')">Provide Liquidity</button>
                            <input type="number" placeholder="Dual Stake Amount" id="dual-${asset}">
                            <select id="dual-asset-${asset}">
                                ${supportedAssets.filter(a => a !== asset).map(a => `<option value="${a}">${a}</option>`).join('')}
                            </select>
                            <button onclick="dualStake('${asset}')">Dual Stake</button>
                            <input type="number" placeholder="Lend Amount" id="lend-${asset}">
                            <button onclick="lendAsset('${asset}')">Lend</button>
                            <input type="number" placeholder="Collateral Amount" id="collateral-${asset}">
                            <input type="number" placeholder="Borrow Amount" id="borrow-${asset}">
                            <button onclick="borrowAsset('${asset}')">Borrow</button>
                            <button onclick="watchAd('${asset}')">Watch Ad</button>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
        updateBalances();
    }
    modal.style.display = 'flex';
}

async function deposit() {
    const amount = prompt('Enter USD amount to deposit:');
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, 'USD', amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Depositing ${mediatedAmount} USD on ${activeChain}`);
        } else {
            const tx = await financeManager.deposit(ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert('Deposit successful!');
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Deposit failed.');
    }
}

async function withdraw() {
    if (!userData.ssn && prompt('Enter amount:') > 1000000) {
        alert('Accounts without SSN are limited to $1M daily bank withdrawals.');
        return;
    }
    const amount = prompt('Enter USD amount to withdraw:');
    try {
        const mediatedAmount = await usdMediator.mediateTransaction(activeChain, 'Stellar', 'USD', amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Withdrawing ${mediatedAmount} USD on ${activeChain}`);
        } else {
            const tx = await financeManager.withdraw(ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert('Withdrawal successful!');
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Withdrawal failed.');
    }
}

function swap() {
    navigateTo('goatepig');
}

function consume() {
    showManageDevices();
}

async function transfer() {
    const modal = document.getElementById('feature-modal');
    const content = document.getElementById('feature-content');
    content.innerHTML = `
        <select id="transfer-asset">
            ${supportedAssets.map(asset => `<option value="${asset}">${asset}</option>`).join('')}
        </select>
        <input type="number" id="transfer-amount" placeholder="Amount">
        <p>USD Denomination: <span id="usd-denomination">0</span></p>
        <input type="text" id="transfer-recipient" placeholder="Pi Address, Username, Phone, Email">
        <button onclick="executeTransfer()">Transfer</button>
        <h3>Transaction History</h3>
        <div id="transaction-history"></div>
    `;
}

async function executeTransfer() {
    const asset = document.getElementById('transfer-asset').value;
    const amount = document.getElementById('transfer-amount').value;
    const recipient = document.getElementById('transfer-recipient').value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction(activeChain, 'Stellar', asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Transferring ${mediatedAmount} ${asset} to ${recipient} on ${activeChain}`);
        } else {
            const tx = await tokenManager.transfer(asset, recipient, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert('Transfer successful!');
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Transfer failed.');
    }
}

async function playGame(game) {
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    const modes = {
        'HomeTeamBets': ['Free', '$1', '$20', '$100'],
        'Goate ScratchOffs': ['Pennies', 'Nickels', 'Dimes', 'Quarters', 'Dollars'],
        'Goate Spades': ['Free', '$1', '$20', '$100'],
        'GerastyxOpol': ['Free', 'Civilian', 'Banker', 'Monopoly'],
        'Goat War': ['Free', '$1', '$20', '$100'],
        'Goate Pity Pat': ['Free', '$1', '$20', '$100']
    };
    const content = document.getElementById('feature-content');
    content.innerHTML = `
        <h3>${game}</h3>
        ${modes[game].map(mode => `<button onclick="startGame('${game}', '${mode}')">${mode}</button>`).join('')}
    `;
}

async function startGame(game, mode) {
    try {
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Starting ${game} in ${mode} mode on ${activeChain}`);
        } else {
            const tx = await entertainmentManager.playGame(game, mode);
            await tx.wait();
            alert(`Started ${game} in ${mode} mode!`);
        }
    } catch (error) {
        console.error(error);
        alert('Failed to start game.');
    }
}

async function watchAds() {
    try {
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log('Watching ad...');
            alert('Ad watched. 50% of revenue added to $GOATE balance.');
        } else {
            const tx = await entertainmentManager.watchAds();
            await tx.wait();
            alert('Ad watched. 50% of revenue added to $GOATE balance.');
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Failed to watch ad.');
    }
}

function zeropointHolographicView() {
    console.log('Accessing ZeropointHolographicView');
}

function validationPortal() {
    const content = document.getElementById('feature-content');
    content.innerHTML = `
        <h3>Validation Portal</h3>
        <p>Rewards: <span id="validation-rewards">0</span> $SD</p>
        <button onclick="checkAvailable()">Check Available</button>
        <div id="shot-view" style="display: none;">
            <p>$SD Shot View</p>
            <button onclick="noHarm()">Do Not Disturb (No Harm, No Foul)</button>
            <button onclick="callPolice()">Call Police (Somebody is Being Harmed)</button>
        </div>
    `;
}

function checkAvailable() {
    document.getElementById('shot-view').style.display = 'block';
}

function noHarm() {
    if (confirm('Confirm with 4-digit PIN:')) {
        console.log('Calling 911 for patrol...');
    }
}

function callPolice() {
    if (confirm('Confirm with 4-digit PIN:')) {
        console.log('Calling 911 for armed officers...');
    }
}

async function stakeAsset(asset) {
    const amount = document.getElementById(`stake-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Staking ${mediatedAmount} ${asset} for 3 months on ${activeChain}`);
        } else {
            const tx = await financeManager.stake(asset, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert(`Staked ${mediatedAmount} ${asset} for 3 months`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Staking failed.');
    }
}

async function farmAsset(asset) {
    const amount = document.getElementById(`farm-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Farming ${mediatedAmount} ${asset} for 6 months on ${activeChain}`);
        } else {
            const tx = await financeManager.farm(asset, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert(`Farming ${mediatedAmount} ${asset} for 6 months`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Farming failed.');
    }
}

async function provideLiquidity(asset) {
    const amount = document.getElementById(`lp-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Providing ${mediatedAmount} ${asset} liquidity for 9 months on ${activeChain}`);
        } else {
            const tx = await financeManager.provideLiquidity(asset, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert(`Providing ${mediatedAmount} ${asset} liquidity for 9 months`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Liquidity provision failed.');
    }
}

async function dualStake(asset) {
    const amount = document.getElementById(`dual-${asset}`).value;
    const secondAsset = document.getElementById(`dual-asset-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Dual staking ${mediatedAmount} ${asset} and ${secondAsset} on ${activeChain}`);
        } else {
            const tx = await financeManager.dualStake(asset, secondAsset, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert(`Dual staking ${mediatedAmount} ${asset} and ${secondAsset}`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Dual staking failed.');
    }
}

async function lendAsset(asset) {
    const amount = document.getElementById(`lend-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Lending ${mediatedAmount} ${asset} on ${activeChain}`);
        } else {
            const tx = await financeManager.lend(asset, ethers.utils.parseUnits(mediatedAmount, 18));
            await tx.wait();
            alert(`Lending ${mediatedAmount} ${asset}`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Lending failed.');
    }
}

async function borrowAsset(asset) {
    const collateral = document.getElementById(`collateral-${asset}`).value;
    const amount = document.getElementById(`borrow-${asset}`).value;
    const pin = prompt('Enter 4-digit PIN:');
    if (pin !== userPin) {
        alert('Invalid PIN.');
        return;
    }
    try {
        const mediatedAmount = await usdMediator.mediateTransaction('Stellar', activeChain, asset, amount);
        const mediatedCollateral = await usdMediator.mediateTransaction('Stellar', activeChain, asset, collateral);
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Borrowing ${mediatedAmount} ${asset} with ${mediatedCollateral} collateral on ${activeChain}`);
        } else {
            const tx = await financeManager.borrow(asset, ethers.utils.parseUnits(mediatedAmount, 18), ethers.utils.parseUnits(mediatedCollateral, 18));
            await tx.wait();
            alert(`Borrowing ${mediatedAmount} ${asset} with ${mediatedCollateral} collateral`);
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Borrowing failed.');
    }
}

async function watchAd(asset) {
    try {
        if (activeChain === 'Pi Network' || activeChain === 'Stellar') {
            console.log(`Watching ad for ${asset} on ${activeChain}`);
            alert('Ad watched. 50% of revenue added to balance.');
        } else {
            const tx = await financeManager.watchAd(asset);
            await tx.wait();
            alert('Ad watched. 50% of revenue added to balance.');
        }
        await updateBalances();
    } catch (error) {
        console.error(error);
        alert('Failed to watch ad.');
    }
}

const EnergyManagerABI = [
    "function registerDevice(string memory deviceId) external",
    "function consumeEnergy(string memory deviceId, uint256 amount) external",
    "function getEnergyConsumed(string memory deviceId) external view returns (uint256)",
    "event EnergyConsumed(string deviceId, uint256 amount)",
    "event DeviceRegistered(string deviceId)"
];

const TokenManagerABI = [
    "function transfer(string memory asset, address to, uint256 amount) external",
    "function addToInsurance(string memory deviceId, uint256 amount) external",
    "function getBalance(string memory asset) external view returns (uint256)",
    "function mint(string memory asset, uint256 amount) external"
];

const EntertainmentManagerABI = [
    "function playGame(string memory game, string memory mode) external",
    "function watchAds() external",
    "event GamePlayed(address indexed player, string game, string mode)",
    "event AdWatched(address indexed viewer, uint256 reward)"
];

const FinanceManagerABI = [
    "function deposit(uint256 amount) external",
    "function withdraw(uint256 amount) external",
    "function stake(string memory asset, uint256 amount) external",
    "function farm(string memory asset, uint256 amount) external",
    "function provideLiquidity(string memory asset, uint256 amount) external",
    "function dualStake(string memory asset1, string memory asset2, uint256 amount) external",
    "function lend(string memory asset, uint256 amount) external",
    "function borrow(string memory asset, uint256 amount, uint256 collateral) external",
    "function watchAd(string memory asset) external"
];
