/**
 * Create Dash Identity for Pentagon AINFT storage
 * 
 * Prerequisites:
 * 1. npm install dash
 * 2. Get testnet funds from faucet: https://testnet-faucet.dash.org/
 * 
 * Usage:
 * MNEMONIC="your twelve word mnemonic" node scripts/create-identity.js
 * 
 * Or to generate new mnemonic:
 * node scripts/create-identity.js --new
 */

const Dash = require('dash');

const NETWORK = process.env.NETWORK || 'testnet';

async function main() {
  let mnemonic = process.env.MNEMONIC;
  
  // Generate new mnemonic if requested
  if (process.argv.includes('--new') || !mnemonic) {
    const client = new Dash.Client({ network: NETWORK });
    const account = await client.getWalletAccount();
    mnemonic = client.wallet.exportWallet();
    await client.disconnect();
    
    console.log('Generated new mnemonic:');
    console.log('─'.repeat(60));
    console.log(mnemonic);
    console.log('─'.repeat(60));
    console.log('\n⚠️  SAVE THIS MNEMONIC SECURELY! You will need it later.\n');
    
    // Get funding address
    const fundingClient = new Dash.Client({
      network: NETWORK,
      wallet: { mnemonic },
    });
    const fundingAccount = await fundingClient.getWalletAccount();
    const address = fundingAccount.getUnusedAddress().address;
    await fundingClient.disconnect();
    
    console.log('Funding address:', address);
    console.log(`\nGet testnet funds: https://testnet-faucet.dash.org/?address=${address}`);
    console.log('\nAfter funding, run again with:');
    console.log(`MNEMONIC="${mnemonic}" node scripts/create-identity.js`);
    return;
  }

  console.log(`Connecting to Dash ${NETWORK}...`);

  const client = new Dash.Client({
    network: NETWORK,
    wallet: { mnemonic },
  });

  try {
    const account = await client.getWalletAccount();
    
    // Check balance
    const balance = account.getTotalBalance();
    console.log('Wallet balance:', balance, 'duffs');
    
    if (balance < 1000000) { // 0.01 DASH minimum
      const address = account.getUnusedAddress().address;
      console.error('\n❌ Insufficient balance!');
      console.error('Get testnet funds:');
      console.error(`https://testnet-faucet.dash.org/?address=${address}`);
      process.exit(1);
    }

    // Check existing identities
    const identityIds = account.identities.getIdentityIds();
    if (identityIds.length > 0) {
      console.log('\nExisting identities found:');
      for (const id of identityIds) {
        const identity = await client.platform.identities.get(id);
        console.log(`  - ${id} (balance: ${identity.getBalance()})`);
      }
      
      console.log('\nUsing first identity for data contract.');
      console.log('Identity ID:', identityIds[0].toString());
      return;
    }

    // Create new identity
    console.log('\nCreating new identity...');
    const identity = await client.platform.identities.register();
    
    console.log('\n✅ Identity Created!');
    console.log('Identity ID:', identity.getId().toString());
    console.log('Balance:', identity.getBalance());
    
    console.log('\nNext: Register data contract with:');
    console.log(`MNEMONIC="${mnemonic}" node scripts/register-data-contract.js`);

  } catch (error) {
    console.error('Error:', error.message);
    if (error.data) console.error('Data:', error.data);
    process.exit(1);
  } finally {
    await client.disconnect();
  }
}

main();
