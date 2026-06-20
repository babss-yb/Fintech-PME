const https = require('https');

const urls = [
  'https://actions.google.com/sounds/v1/weather/rain_heavy_loud.ogg',
  'https://actions.google.com/sounds/v1/crowds/restaurant_ambience.ogg',
  'https://actions.google.com/sounds/v1/ambiences/outdoor_summer_ambience.ogg',
  'https://actions.google.com/sounds/v1/water/rain_on_roof.ogg'
];

urls.forEach(url => {
  https.get(url, (res) => {
    console.log(`${url} -> ${res.statusCode}`);
  }).on('error', (e) => {
    console.error(e);
  });
});
