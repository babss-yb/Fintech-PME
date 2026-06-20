const https = require('https');
const fs = require('fs');
const path = require('path');

const url = 'https://upload.wikimedia.org/wikipedia/commons/4/4c/Fire_crackling_and_popping.ogg';
const dest = path.join(__dirname, 'assets', 'sounds', 'fire.ogg');

function download(url, dest) {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(dest);
    https.get(url, { headers: { 'User-Agent': 'FocusFlow/1.0' } }, (response) => {
      if (response.statusCode >= 300 && response.statusCode < 400 && response.headers.location) {
        file.close();
        download(response.headers.location, dest).then(resolve).catch(reject);
        return;
      }
      if (response.statusCode !== 200) {
        file.close();
        reject(new Error(`Failed to get '${url}' (${response.statusCode})`));
        return;
      }
      response.pipe(file);
      file.on('finish', () => file.close(resolve));
    }).on('error', (err) => {
      reject(err);
    });
  });
}

console.log('Downloading fire sound...');
download(url, dest)
  .then(() => console.log('✅ fire.ogg downloaded successfully!'))
  .catch(err => console.error('❌ Error:', err.message));
