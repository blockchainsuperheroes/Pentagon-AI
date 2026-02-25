/**
 * Register Pentagon AINFT Data Contract on Dash Platform
 * 
 * Prerequisites:
 * 1. npm install dash
 * 2. Get testnet funds from faucet: https://testnet-faucet.dash.org/
 * 3. Create identity first with: node scripts/create-identity.js
 * 
 * Usage:
 * MNEMONIC="your twelve word mnemonic" node scripts/register-data-contract.js
 */

const Dash = require('dash');
const fs = require('fs');
const path = require('path');

const NETWORK = process.env.NETWORK || 'testnet';

async function main() {
  const mnemonic = process.env.MNEMONIC;
  if (!mnemonic) {
    console.error('Error: MNEMONIC environment variable required');
    console.error('Get testnet funds first: https://testnet-faucet.dash.org/');
    process.exit(1);
  }

  console.log(`Connecting to Dash ${NETWORK}...`);

  const client = new Dash.Client({
    network: NETWORK,
    wallet: { mnemonic },
  });

  try {
    // Get identity
    const account = await client.getWalletAccount();
    const identityIds = account.identities.getIdentityIds();
    
    if (identityIds.length === 0) {
      console.log('No identity found. Creating one...');
      const identity = await client.platform.identities.register();
      console.log('Created identity:', identity.getId().toString());
    }
    
    const identityId = identityIds[0] || (await client.platform.identities.register()).getId();
    const identity = await client.platform.identities.get(identityId);
    
    console.log('Using identity:', identity.getId().toString());
    console.log('Identity balance:', identity.getBalance());

    // Load contract schema
    const contractPath = path.join(__dirname, '../contracts/data-contract.json');
    const contractSchema = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
    
    // Remove placeholder fields
    delete contractSchema.$id;
    delete contractSchema.version;
    delete contractSchema.ownerId;

    console.log('Registering data contract...');
    console.log('Schema:', JSON.stringify(contractSchema.documentSchemas, null, 2));

    // Create and register contract
    const contract = await client.platform.contracts.create(
      contractSchema.documentSchemas,
      identity
    );

    await client.platform.contracts.publish(contract, identity);

    const contractId = contract.getId().toString();
    
    console.log('\n✅ Data Contract Registered!');
    console.log('Contract ID:', contractId);
    console.log('Owner ID:', identity.getId().toString());
    
    // Save contract ID
    const outputPath = path.join(__dirname, '../.contract-id');
    fs.writeFileSync(outputPath, contractId);
    console.log(`\nContract ID saved to ${outputPath}`);

    // Update package.json with contract ID
    console.log('\nUpdate packages/dash-storage/src/index.ts with:');
    console.log(`  dataContractId: '${contractId}',`);

  } catch (error) {
    console.error('Error:', error.message);
    if (error.code) console.error('Code:', error.code);
    process.exit(1);
  } finally {
    await client.disconnect();
  }
}

main();
