const https = require('https');
const fs = require('fs');
const path = require('path');

const sounds = [
  { name: 'cafe.ogg', url: 'https://actions.google.com/sounds/v1/ambiences/coffee_shop.ogg' },
  { name: 'fire.ogg', url: 'https://upload.wikimedia.org/wikipedia/commons/2/23/Fireplace.ogg' }
];

const destFolder = path.join(__dirname, 'assets', 'sounds');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': 'FocusFlow/1.0 (test@test.com)' } }, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        file.close();
        download(response.headers.location, dest).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        file.close();
        fs.unlink(dest, () => {});
        reject(new Error(`Failed to get '${url}' (${response.statusCode})`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => file.close(resolve));
    }).on('error', (err) => {
      fs.unlink(dest, () => {});
      reject(err);
    });
  });
}

async function run() {
  for (const sound of sounds) {
    try {
      console.log(`Downloading ${sound.name}...`);
      await download(sound.url, path.join(destFolder, sound.name));
      console.log(`✅ ${sound.name} downloaded successfully!`);
    } catch (err) {
      console.error(`❌ Error downloading ${sound.name}:`, err.message);
    }
  }
}

run();
