const fs = require('fs');
const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

let codigo;

try {
    codigo = fs.readFileSync(process.argv[2], { encoding: 'utf8' }).split('\n\n')[0].split('\n');
} catch (err) {
    process.stdout.write('\n[ERROR] input file not found\n', () => {
        process.exit(2);
    });
}

let pc = 0;

let mem = {};

function mem_add(name, type, val) {
    if (type === 'char') {
        val = val.length === 1 ? ' ' : val.substring(1,val.length-1);
    }
    mem[name] = [type, val];
    mem_set(name, val);
};
function mem_set(name, val) {
    if (mem[name][0] === 'char') mem[name][1] = val;
    else if (mem[name][0] === 'integer') mem[name][1] = parseInt(val);
    else if (mem[name][0] === 'real') mem[name][1] = parseFloat(val);
    else if (mem[name][0] === 'boolean') mem[name][1] = !!+(val);
}

function scan (type) {
    return new Promise(resolve => {
        process.stdout.write('\n', () => {
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
            });
        });
    });
}

async function main () {
    while (pc < codigo.length) {
        const [opcode, dest, arg1, arg2] = codigo[pc].split(' ');
        if (opcode === 'halt') {
            break;
        } else if (opcode === 'read') {
            let val = await scan(dest);
            mem_set(arg1, val);
        } else if (opcode === 'write') {
            if (mem[arg1][0] === 'char') {
                let c = mem[arg1][1] === '\\\'' ? '\''
                : mem[arg1][1] === '\\n'  ? '\n'
                : mem[arg1][1] === '\\t'  ? '\t'
                : mem[arg1][1] === '\\0'  ? '\0'
                : mem[arg1][1] === '\\\\' ? '\\'
                : mem[arg1][1];
                process.stdout.write('' + c);
            } else {
                process.stdout.write('' + mem[arg1][1]);
            }
        } else if (opcode === 'declare') {
            mem_add(dest, arg1, arg2);
        } else if (opcode === 'assign') {
            mem_set(dest, mem[arg1][1])
        } else if (opcode === 'jump') {
            pc = +dest - 1;
        } else if (opcode === 'branch') {
            if (!mem[dest][1]) pc = +arg1 - 1;
        } else if (opcode === '=') {   // relop
            mem_set(dest, mem[arg1][1] == mem[arg2][1]);
        } else if (opcode === '<') {   // relop
            mem_set(dest, mem[arg1][1] < mem[arg2][1]);
        } else if (opcode === '<=') {  // relop
            mem_set(dest, mem[arg1][1] <= mem[arg2][1]);
        } else if (opcode === '>') {   // relop
            mem_set(dest, mem[arg1][1] > mem[arg2][1]);
        } else if (opcode === '>=') {  // relop
            mem_set(dest, mem[arg1][1] >= mem[arg2][1]);
        } else if (opcode === '!=') {  // relop
            mem_set(dest, mem[arg1][1] != mem[arg2][1]);
        } else if (opcode === '-') {   // minus
            mem_set(dest, mem[arg1][1] - mem[arg2][1]);
        } else if (opcode === '+') {   // addop
            mem_set(dest, mem[arg1][1] + mem[arg2][1]);
        } else if (opcode === 'or') {  // addop
            mem_set(dest, mem[arg1][1] || mem[arg2][1]);
        } else if (opcode === '*') {   // mulop
            mem_set(dest, mem[arg1][1] * mem[arg2][1]);
        } else if (opcode === '/') {  // mulop
            mem_set(dest, mem[arg1][1] / mem[arg2][1]);
        } else if (opcode === 'div') { // mulop
            mem_set(dest, mem[arg1][1] / mem[arg2][1]);
        } else if (opcode === 'mod') { // mulop
            mem_set(dest, mem[arg1][1] % mem[arg2][1]);
        } else if (opcode === 'and') { // mulop
            mem_set(dest, mem[arg1][1] && mem[arg2][1]);
        } else if (opcode === 'not') { // not
            mem_set(dest, !mem[arg1][1]);
        } else {
            process.stdout.write('\n[ERROR] invalid opcode at pc ' + pc + '\n', () => {
                process.exit(4);
            });
        }
        pc++;
    }
    return 0;
}

main().then(a => {
    process.exit(a);
});