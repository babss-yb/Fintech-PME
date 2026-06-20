const https = require('https');

const urls = [
  'https://actions.google.com/sounds/v1/crowds/large_crowd.ogg',
  'https://actions.google.com/sounds/v1/ambiences/coffee_shop.ogg',
  'https://actions.google.com/sounds/v1/crowds/cafe_crowd.ogg',
  'https://actions.google.com/sounds/v1/foley/camp_fire.ogg',
  'https://actions.google.com/sounds/v1/foley/fire.ogg',
  'https://actions.google.com/sounds/v1/foley/fire_crackle.ogg'
];

urls.forEach(url => {
  https.get(url, (res) => {
    console.log(`${url} -> ${res.statusCode}`);
  }).on('error', (e) => {
    console.error(e);
  });
});
