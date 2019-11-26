const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

let codigo = fs.readFileSync(process.argv[2], { encoding: 'utf8' }).split('\n\n')[0].split('\n');

let pc = 0;

let mem = {};

function scan (type) {
    return new Promise(resolve => {
        rl.question('', answer => {
            if (type === 'char') {
                return isNaN(+answer) ? resolve(answer[0]) : '\0';
            } else if (type === 'integer') {
                return resolve(parseInt(answer) || 0);
            } else if (type === 'real') {
                return resolve(parseFloat(answer) || 0);
            } else if (type === 'boolean') {
                return resolve(!!parseInt(answer));
            } else {
                return resolve(0);
            }
        })
    });
}

async function main () {
    while (pc < codigo.length) {
        const [opcode, dest, arg1, arg2] = codigo[pc].split(' ');
        if (opcode === 'halt') {
            break;
        } else if (opcode === 'read') {
            mem[arg1] = await scan(dest);
        } else if (opcode === 'write') {
            console.log(arg1);
        }
    }
}

main();