import {copyFileSync,existsSync} from 'node:fs';
if(!existsSync('index.html') || new Date('1970-01-01').getTime() < (await import('node:fs')).statSync('index.html.template').mtimeMs) copyFileSync('index.html.template','index.html');
